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
    parent_id_field: "fmu_id",
    translated_fields: %w[name]
  },
  {
    item_type: "Operator",
    parent_id_field: "operator_id",
    translated_fields: %w[name details]
  },
  {
    item_type: "Observer",
    parent_id_field: "observer_id",
    translated_fields: %w[name]
  }
].freeze

# Known class renames between Rails versions stored in PaperTrail YAML
YAML_CLASS_SUBSTITUTIONS = [
  ["ActiveRecord::Attribute::", "ActiveModel::Attribute::"],
  ["ActiveModel::Type::Text", "ActiveModel::Type::String"],
  ["OperatorDocumentUploader", "DocumentFileUploader"],
  [/LogoUploader::Uploader\d+/, "LogoUploader"]
].freeze

def paper_trail_print_progress(processed, total)
  return unless processed % 100 == 0 || processed == total

  pct = (total > 0) ? (processed * 100.0 / total).round(1) : 100.0
  print "\r  #{processed}/#{total} (#{pct}%)"
  $stdout.flush
end

namespace :paper_trail do
  desc "Run all paper_trail cleanup tasks in order. Set FOR_REAL=true to apply."
  task clean_up_all: %i[fix_yaml_serialization merge_old_translations strip_fmu_geojson_properties clean_up deduplicate squash_create_updates strip_create_duplicates strip_blank_changes]

  desc "Fix YAML serialization issues in PaperTrail versions caused by Rails class renames. also removes uploader objects. Set FOR_REAL=true to apply."
  task fix_yaml_serialization: :environment do
    puts "Fixing YAML serialization issues in PaperTrail versions caused by Rails class renames, and removing uploader objects..."
    for_real = ENV["FOR_REAL"] == "true"
    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"

    scope = PaperTrail::Version.where(
      "object LIKE '%!ruby/object:%' OR object_changes LIKE '%!ruby/object:%'"
    )
    total = scope.count
    puts "Found #{total} versions with serialized Ruby objects.\n\n"

    normalize_uploaders = ->(obj, key) do
      obj.class.name.to_s.end_with?("Uploader") ? obj.model.read_attribute(key) : obj
    end

    fixed = 0
    failed = 0
    processed = 0

    scope.find_each do |version|
      processed += 1
      paper_trail_print_progress(processed, total)
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

    puts "\n\nVersions fixed: #{fixed}"
    puts "Versions with errors: #{failed}"
  end

  desc "Remove object_changes entries where old and new values are both blank (nil or empty string) across all versions. Deletes update versions that become empty. Set FOR_REAL=true to apply."
  task strip_blank_changes: :environment do
    puts "Stripping blank-to-blank changes from all PaperTrail versions..."
    for_real = ENV["FOR_REAL"] == "true"
    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"

    scope = PaperTrail::Version.where.not(object_changes: nil).where.not(object_changes: "")
    total = scope.count
    processed = 0
    deleted = 0
    updated = 0
    ids_to_delete = []

    puts "Scanning #{total} versions..."

    scope.find_each do |version|
      processed += 1
      paper_trail_print_progress(processed, total)

      changes = PaperTrail.serializer.load(version.object_changes)
      stripped = changes.reject { |_, (old_val, new_val)| old_val.to_s == new_val.to_s }
      meaningful = stripped.except("updated_at")
      next if stripped == changes && meaningful.any?

      if meaningful.empty? && version.event == "update"
        ids_to_delete << version.id
        deleted += 1
      else
        version.update_column(:object_changes, PaperTrail.serializer.dump(stripped)) if for_real
        updated += 1
      end
    end

    if for_real && ids_to_delete.any?
      PaperTrail::Version.where(id: ids_to_delete).delete_all
    end

    puts "\n#{deleted} update versions deleted (all changes were blank-to-blank)"
    puts "#{updated} versions stripped of blank changes"
  end

  desc "Merge EN translation versions (Operator::Translation, Fmu::Translation, Observer::Translation) into parent model history, then delete the translation versions. Set FOR_REAL=true to apply. Optionally filter with ITEM_TYPE=Foo."
  task merge_old_translations: :environment do
    puts "Merging EN translation versions into parent model history..."
    for_real = ENV["FOR_REAL"] == "true"
    filter_item_type = ENV["ITEM_TYPE"]

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"
    puts "Filtering to item_type=#{filter_item_type}" if filter_item_type

    configs = PAPER_TRAIL_MERGE_TRANSLATIONS_CONFIG
    configs = configs.select { |c| c[:item_type] == filter_item_type } if filter_item_type

    configs.each do |config|
      item_type = config[:item_type]
      parent_id_field = config[:parent_id_field]
      translated_fields = config[:translated_fields]
      translation_item_type = "#{item_type}::Translation"

      scope = PaperTrail::Version.where(item_type: translation_item_type).where.not(event: "destroy")
      total = scope.count
      processed = 0
      merged_into_existing = 0
      new_versions_created = 0
      skipped_non_en = 0
      skipped_no_changes = 0

      puts "  Scanning #{total} #{translation_item_type} versions..."

      scope.order(:created_at, :id).find_each do |version|
        processed += 1
        paper_trail_print_progress(processed, total)

        next if version.object_changes.blank?

        changes = PaperTrail.serializer.load(version.object_changes)
        object_state = version.object.present? ? PaperTrail.serializer.load(version.object) : {}

        # Determine locale: check object_changes first (always present for creates),
        # then fall back to object (the pre-change state for updates that didn't change locale)
        locale = if changes.key?("locale")
          locale_val = changes["locale"]
          locale_val.is_a?(Array) ? locale_val.last : locale_val
        else
          object_state["locale"]
        end

        unless locale.to_s == "en"
          skipped_non_en += 1
          next
        end

        # Determine parent id: check object_changes first (creates), then object (updates)
        parent_id = if changes.key?(parent_id_field)
          id_val = changes[parent_id_field]
          id_val.is_a?(Array) ? id_val.last : id_val
        else
          object_state[parent_id_field]
        end

        if parent_id.nil?
          skipped_no_changes += 1
          next
        end

        # Keep only the translated fields that actually changed (skip blank-to-blank noise)
        translated_changes = changes.slice(*translated_fields).reject do |_, (old_val, new_val)|
          old_val.to_s == new_val.to_s
        end
        if translated_changes.empty?
          skipped_no_changes += 1
          next
        end

        # Look for a parent version within 10 seconds with the same whodunnit to merge into
        matching_parent = PaperTrail::Version
          .where(item_type: item_type, item_id: parent_id, whodunnit: version.whodunnit)
          .where("created_at BETWEEN ? AND ?", version.created_at - 10.seconds, version.created_at + 10.seconds)
          .order(Arel.sql("ABS(EXTRACT(EPOCH FROM (created_at - #{ActiveRecord::Base.connection.quote(version.created_at)})))"))
          .first

        if matching_parent
          existing_changes = matching_parent.object_changes.present? ? PaperTrail.serializer.load(matching_parent.object_changes) : {}
          # Existing parent changes take priority (translated fields should not overwrite non-translation changes)
          merged = translated_changes.merge(existing_changes)
          matching_parent.update_column(:object_changes, PaperTrail.serializer.dump(merged)) if for_real
          merged_into_existing += 1
        else
          if for_real
            PaperTrail::Version.create!(
              item_type: item_type,
              item_id: parent_id,
              event: "update",
              whodunnit: version.whodunnit,
              object_changes: PaperTrail.serializer.dump(translated_changes),
              created_at: version.created_at
            )
          end
          new_versions_created += 1
        end
      end

      all_translation_versions = PaperTrail::Version.where(item_type: translation_item_type)
      total_to_delete = all_translation_versions.count

      puts "\n\n#{translation_item_type}:"
      puts "  #{merged_into_existing} versions merged into existing parent versions"
      puts "  #{new_versions_created} new parent versions created"
      puts "  #{skipped_non_en} versions skipped (non-EN locale)"
      puts "  #{skipped_no_changes} versions skipped (no translated field changes or missing parent id)"
      puts "  #{total_to_delete} translation versions to delete"

      next unless for_real

      all_translation_versions.delete_all
      puts "  Deleted #{total_to_delete} #{translation_item_type} versions."
    end
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

      scope = PaperTrail::Version.where(item_type: item_type)
      total = scope.count
      processed = 0
      puts "  Scanning #{total} #{item_type} versions..."

      scope.find_each do |version|
        processed += 1
        paper_trail_print_progress(processed, total)
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
        strip_total = ids_to_strip.size
        strip_processed = 0
        PaperTrail::Version.where(id: ids_to_strip).find_each do |version|
          strip_processed += 1
          paper_trail_print_progress(strip_processed, strip_total)
          changes = version.changeset
          stripped_fields.each { |f| changes.delete(f) }
          version.update_column(:object_changes, PaperTrail.serializer.dump(changes))
        end
        puts "\n  Stripped."
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
    total = grouped.size
    processed = 0

    grouped.each do |create_id, update_ids|
      processed += 1
      paper_trail_print_progress(processed, total)
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

    puts "" if total > 0
    PaperTrail::Version.where(id: update_ids_to_delete).delete_all if update_ids_to_delete.any?
    puts "Squashed #{update_ids_to_delete.size} update versions into their create versions."
  end

  desc "Remove changes from update versions that duplicate the directly preceding create version for the same item. Deletes the update if no changes remain. Set FOR_REAL=true to apply."
  task strip_create_duplicates: :environment do
    puts "Stripping changes from update versions that duplicate their directly preceding create version..."
    for_real = ENV["FOR_REAL"] == "true"
    verbose = ENV["VERBOSE"] == "true"
    filter_item_type = ENV["ITEM_TYPE"]

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"
    puts "Filtering to item_type=#{filter_item_type}" if filter_item_type

    exclude_models = ["Operator::Translation", "Fmu::Translation", "Observer::Translation", "GovFile"]

    type_filter = filter_item_type ? "AND item_type = #{ActiveRecord::Base.connection.quote(filter_item_type)}" : ""
    exclude_filter = "AND item_type NOT IN (#{exclude_models.map { |m| ActiveRecord::Base.connection.quote(m) }.join(", ")})"

    pairs = ActiveRecord::Base.connection.select_rows(<<~SQL)
      WITH ranked AS (
        SELECT id, event, item_type, item_id,
               LAG(event) OVER (PARTITION BY item_type, item_id ORDER BY created_at, id) AS prev_event,
               LAG(id)    OVER (PARTITION BY item_type, item_id ORDER BY created_at, id) AS prev_id
        FROM versions
        WHERE 1=1 #{type_filter} #{exclude_filter}
      )
      SELECT prev_id AS create_id, id AS update_id
      FROM ranked
      WHERE event = 'update' AND prev_event = 'create'
    SQL

    puts "Found #{pairs.size} (create, update) sibling pairs to inspect."

    ids_to_delete = []
    ids_to_update = {}

    create_versions = PaperTrail::Version.where(id: pairs.map(&:first).uniq).index_by(&:id)
    update_versions = PaperTrail::Version.where(id: pairs.map(&:last)).index_by(&:id)

    pairs.each do |create_id, update_id|
      create_version = create_versions[create_id.to_i]
      update_version = update_versions[update_id.to_i]
      next if create_version&.object_changes.blank? || update_version&.object_changes.blank?

      create_changes = create_version.changeset.except("updated_at")
      update_changes = update_version.changeset.except("updated_at")

      duplicate_keys = update_changes.select { |field, pair| create_changes[field] == pair }.keys
      next if duplicate_keys.empty?

      reduced = update_changes.except(*duplicate_keys)

      if verbose
        diff_seconds = (update_version.created_at - create_version.created_at).to_i
        time_diff = ActiveSupport::Duration.build(diff_seconds).inspect
        base_info = "#{update_version.item_type} ##{update_version.item_id} (create: #{create_version.id}, update: #{update_version.id}, +#{time_diff})"
      end

      if reduced.empty?
        puts "  [DELETE] #{base_info}" if verbose
        ids_to_delete << update_version.id
      else
        puts "  [STRIP]  #{base_info} removing: #{duplicate_keys.join(", ")}" if verbose
        ids_to_update[update_version.id] = PaperTrail.serializer.dump(reduced)
      end
    end

    puts "#{ids_to_delete.size} update versions to delete (all changes duplicated the create)"
    puts "#{ids_to_update.size} update versions to strip duplicate changes from"

    next unless for_real

    PaperTrail::Version.where(id: ids_to_delete).delete_all if ids_to_delete.any?
    puts "Deleted #{ids_to_delete.size} update versions."

    ids_to_update.each do |id, object_changes|
      PaperTrail::Version.where(id: id).update_all(object_changes: object_changes)
    end
    puts "Updated #{ids_to_update.size} update versions."
  end

  desc "Strip geojson['properties'] from Fmu version object_changes. Deletes version if geojson is the only change and becomes identical after stripping. Set FOR_REAL=true to apply."
  task strip_fmu_geojson_properties: :environment do
    puts "Stripping geojson['properties'] from Fmu version object_changes, and deleting versions where geojson is the only change and becomes identical after stripping..."
    for_real = ENV["FOR_REAL"] == "true"

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"

    ids_to_delete = []
    ids_to_update = {}

    fmu_scope = PaperTrail::Version.where(item_type: "Fmu")
    total = fmu_scope.count
    processed = 0

    fmu_scope.find_each do |version|
      processed += 1
      paper_trail_print_progress(processed, total)
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

    puts "\n#{ids_to_delete.size} versions to delete (geojson-only change, properties was the only diff)"
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
