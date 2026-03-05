PAPER_TRAIL_CLEAN_CONFIG = [
  {
    item_type: "Operator",
    stripped_fields: %w[
      percentage_valid_documents_all
      percentage_valid_documents_fmu
      percentage_valid_documents_country
      country_doc_rank
      country_operators
      score_absolute
      obs_per_visit
      updated_at
    ]
  },
  {
    item_type: "Fmu",
    stripped_fields: %w[geometry properties updated_at]
  }
].freeze

PAPER_TRAIL_MERGE_TRANSLATIONS_CONFIG = [
  {
    item_type: "Fmu",
    translated_fields: %w[name]
  },
  {
    item_type: "Operator",
    translated_fields: %w[name details]
  }
].freeze

# Known class renames between Rails versions stored in PaperTrail YAML
YAML_CLASS_SUBSTITUTIONS = [
  ["ActiveRecord::Attribute::", "ActiveModel::Attribute::"],
  ["ActiveModel::Type::Text", "ActiveModel::Type::String"],
  ["OperatorDocumentUploader", "DocumentFileUploader"],
  [/LogoUploader::Uploader\d+/, "LogoUploader"]
].freeze

namespace :paper_trail do
  desc "Run all paper_trail cleanup tasks in order. Set FOR_REAL=true to apply."
  task clean_up_all: %i[fix_yaml_serialization strip_fmu_geojson_properties clean_up deduplicate squash_create_updates]

  desc "Fix YAML serialization issues in PaperTrail versions caused by Rails class renames. also removes uploader objects. Set FOR_REAL=true to apply."
  task fix_yaml_serialization: :environment do
    puts "Fixing YAML serialization issues in PaperTrail versions caused by Rails class renames, and removing uploader objects..."
    for_real = ENV["FOR_REAL"] == "true"
    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"

    scope = PaperTrail::Version.where(
      "object LIKE '%!ruby/object:%' OR object_changes LIKE '%!ruby/object:%'"
    )
    puts "Found #{scope.count} versions with serialized Ruby objects.\n\n"

    normalize_uploaders = ->(obj, key) do
      obj.class.name.to_s.end_with?("Uploader") ? obj.model.read_attribute(key) : obj
    end

    fixed = 0
    failed = 0

    scope.find_each do |version|
      updates = {}

      %i[object object_changes].each do |col|
        raw = version.read_attribute(col)
        next if raw.blank?

        substituted = raw.dup
        YAML_CLASS_SUBSTITUTIONS.each { |old, new_name| substituted.gsub!(old, new_name) }
        next if substituted == raw

        begin
          loaded = PaperTrail.serializer.load(substituted)
          normalized = loaded.map do |k, v|
            if col == :object
              [k, normalize_uploaders.call(v, k)]
            elsif col == :object_changes && v.is_a?(Array)
              [k, v.map { |change| normalize_uploaders.call(change, k) }]
            else
              raise "Unexpected value type in #{col}: #{v.class}"
            end
          end.to_h
          updates[col] = PaperTrail.serializer.dump(normalized)
        rescue => e
          puts "  [FAIL] Version #{version.id} #{col}: #{e.message}"
          failed += 1
        end
      end

      next if updates.empty?

      version.update_columns(updates) if for_real
      fixed += 1
    end

    puts "\nVersions fixed: #{fixed}"
    puts "Versions with errors: #{failed}"
  end

  desc "Clean versions for all models - delete where only ignored fields changed, strip those fields from the rest. Set FOR_REAL=true to apply. Optionally filter with ITEM_TYPE=Foo."
  task clean_up: :environment do
    puts "Cleaning up PaperTrail versions by removing ignored fields and deleting versions with only ignored fields changed..."
    for_real = ENV["FOR_REAL"] == "true"
    filter_item_type = ENV["ITEM_TYPE"]

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"
    puts "Filtering to item_type=#{filter_item_type}" if filter_item_type

    configs = PAPER_TRAIL_CLEAN_CONFIG
    configs = configs.select { |c| c[:item_type] == filter_item_type } if filter_item_type

    configs.each do |config|
      item_type = config[:item_type]
      stripped_fields = config[:stripped_fields]
      ids_to_delete = []
      ids_to_strip = []

      PaperTrail::Version.where(item_type: item_type).find_each do |version|
        next if version.object_changes.blank?

        changes = version.changeset
        next unless (changes.keys & stripped_fields).any?

        if (changes.keys - stripped_fields).empty? && version.event == "update"
          ids_to_delete << version.id
        else
          ids_to_strip << version.id
        end
      end

      puts "\n#{item_type}:"
      puts "  #{ids_to_delete.size} versions to delete (only ignored fields changed)"
      puts "  #{ids_to_strip.size} versions to strip ignored fields from"

      next unless for_real

      if ids_to_delete.any?
        PaperTrail::Version.where(id: ids_to_delete).delete_all
        puts "  Deleted."
      end

      if ids_to_strip.any?
        PaperTrail::Version.where(id: ids_to_strip).find_each do |version|
          changes = version.changeset
          stripped_fields.each { |f| changes.delete(f) }
          version.update_column(:object_changes, PaperTrail.serializer.dump(changes))
        end
        puts "  Stripped."
      end
    end
  end

  desc "Remove duplicate versions with identical object_changes created within 3 minutes of each other. Set FOR_REAL=true to apply."
  task deduplicate: :environment do
    puts "Removing duplicate PaperTrail versions with identical object_changes created within 3 minutes of each other..."
    for_real = ENV["FOR_REAL"] == "true"

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"

    ids_to_delete = ActiveRecord::Base.connection.select_values(<<~SQL)
      WITH lagged AS (
        SELECT id,
               object_changes,
               created_at,
               LAG(object_changes) OVER (PARTITION BY item_type, item_id ORDER BY created_at, id) AS prev_object_changes,
               LAG(created_at)     OVER (PARTITION BY item_type, item_id ORDER BY created_at, id) AS prev_created_at
        FROM versions
        WHERE event = 'update'
      )
      SELECT id FROM lagged
      WHERE object_changes = prev_object_changes
        AND EXTRACT(EPOCH FROM (created_at - prev_created_at)) <= 3 * 60
    SQL

    puts "Found #{ids_to_delete.size} duplicate versions."

    if for_real && ids_to_delete.any?
      PaperTrail::Version.where(id: ids_to_delete).delete_all
      puts "Deleted."
    end
  end

  desc "Merge update versions into preceding create versions when done by the same user within 10 seconds, then delete the update. Set FOR_REAL=true to apply."
  task squash_create_updates: :environment do
    puts "Squashing PaperTrail update versions into their create version when they have the same whodunnit and are created within 10 seconds of each other..."
    for_real = ENV["FOR_REAL"] == "true"

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"

    exclude_models = ["Operator::Translation", "Fmu::Translation", "Observer::Translation"]

    pairs = ActiveRecord::Base.connection.select_rows(<<~SQL)
      SELECT c.id, u.id
      FROM versions c
      JOIN versions u
        ON  u.item_type = c.item_type
        AND u.item_id   = c.item_id
        AND u.event     = 'update'
        AND (u.whodunnit = c.whodunnit OR (u.whodunnit IS NULL AND c.whodunnit IS NULL))
        AND EXTRACT(EPOCH FROM (u.created_at - c.created_at)) BETWEEN 0 AND 10
        WHERE c.event = 'create' AND c.item_type NOT IN (#{exclude_models.map { |m| "'#{m}'" }.join(", ")})
      ORDER BY c.id, u.created_at, u.id
    SQL

    grouped = pairs.each_with_object({}) do |(create_id, update_id), h|
      (h[create_id.to_i] ||= []) << update_id.to_i
    end

    puts "Found #{grouped.size} create versions with #{pairs.size} follow-up updates to squash."

    next unless for_real

    update_ids_to_delete = []

    grouped.each do |create_id, update_ids|
      create_version = PaperTrail::Version.find(create_id)
      next if create_version.object_changes.blank?

      # create_changes = PaperTrail.serializer.load(create_version.object_changes)
      create_changes = create_version.changeset

      # Accumulate all update changes in order; later updates overwrite earlier for the same field
      update_changes = PaperTrail::Version.where(id: update_ids).order(:created_at, :id).each_with_object({}) do |update_version, acc|
        next if update_version.object_changes.blank?

        update_ids_to_delete << update_version.id
        update_changes = update_version.changeset
        acc.merge!(update_changes)
      end

      # For fields in create: keep nil as origin, use update's final value
      # For fields only in update: treat as [nil, new_val] since record started with nil
      merged = create_changes.merge(update_changes.transform_values { |(_old, new_val)| [nil, new_val] }) do |_field, create_pair, (_nil, new_val)|
        [create_pair[0], new_val]
      end

      create_version.update_column(:object_changes, PaperTrail.serializer.dump(merged))
    end

    PaperTrail::Version.where(id: update_ids_to_delete).delete_all if update_ids_to_delete.any?
    puts "Squashed #{update_ids_to_delete.size} update versions into their create versions."
  end

  desc "Strip geojson['properties'] from Fmu version object_changes. Deletes version if geojson is the only change and becomes identical after stripping. Set FOR_REAL=true to apply."
  task strip_fmu_geojson_properties: :environment do
    puts "Stripping geojson['properties'] from Fmu version object_changes, and deleting versions where geojson is the only change and becomes identical after stripping..."
    for_real = ENV["FOR_REAL"] == "true"

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"

    ids_to_delete = []
    ids_to_update = {}

    PaperTrail::Version.where(item_type: "Fmu").find_each do |version|
      next if version.object_changes.blank?

      changes = PaperTrail.serializer.load(version.object_changes)
      next unless changes.key?("geojson")

      old_geojson, new_geojson = changes["geojson"]
      old_geojson = JSON.parse(old_geojson) if old_geojson.is_a?(String)
      new_geojson = JSON.parse(new_geojson) if new_geojson.is_a?(String)
      old_geojson&.delete("properties")
      new_geojson&.delete("properties")

      if old_geojson == new_geojson
        changes.delete("geojson")
      else
        changes["geojson"] = [old_geojson&.to_json, new_geojson&.to_json]
      end

      if (changes.keys - %w[updated_at]).empty? && version.event == "update"
        ids_to_delete << version.id
      else
        ids_to_update[version.id] = PaperTrail.serializer.dump(changes)
      end
    end

    puts "#{ids_to_delete.size} versions to delete (geojson-only change, properties was the only diff)"
    puts "#{ids_to_update.size} versions to update (strip properties from geojson)"

    next unless for_real

    PaperTrail::Version.where(id: ids_to_delete).delete_all if ids_to_delete.any?
    puts "Deleted #{ids_to_delete.size} versions."

    ids_to_update.each do |id, object_changes|
      PaperTrail::Version.where(id: id).update_all(object_changes: object_changes)
    end
    puts "Updated #{ids_to_update.size} versions."
  end
end
