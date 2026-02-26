namespace :paper_trail do
  desc "Clean Operator versions - delete where only ignored fields changed, strip those fields from object_changes in the rest. Set FOR_REAL=true to apply."
  task clean_operators: :environment do
    for_real = ENV["FOR_REAL"] == "true"

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"

    stripped_fields = %w[
      percentage_valid_documents_all
      percentage_valid_documents_fmu
      percentage_valid_documents_country
      country_doc_rank
      country_operators
    ]
    ignored_fields = stripped_fields + %w[updated_at]
    ids_to_delete = []
    ids_to_strip = []

    PaperTrail::Version.where(item_type: "Operator", event: "update").find_each do |version|
      next if version.object_changes.blank?

      changed_keys = version.changeset.keys
      next unless (changed_keys & stripped_fields).any?

      if (changed_keys - ignored_fields).empty?
        ids_to_delete << version.id
      else
        ids_to_strip << version.id
      end
    end

    puts "Found #{ids_to_delete.size} versions to delete (only ignored fields changed)."
    puts "Found #{ids_to_strip.size} versions to strip ignored fields from."

    if for_real
      if ids_to_delete.any?
        PaperTrail::Version.where(id: ids_to_delete).delete_all
        puts "Deleted #{ids_to_delete.size} versions."
      end

      if ids_to_strip.any?
        PaperTrail::Version.where(id: ids_to_strip).find_each do |version|
          changes = version.changeset
          stripped_fields.each { |f| changes.delete(f) }
          version.update_column(:object_changes, PaperTrail.serializer.dump(changes))
        end
        puts "Stripped ignored fields from #{ids_to_strip.size} versions."
      end
    end
  end

  desc "Clean Fmu versions - delete where only ignored fields changed, strip those fields from object_changes in the rest. Set FOR_REAL=true to apply."
  task clean_fmus: :environment do
    for_real = ENV["FOR_REAL"] == "true"

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"

    stripped_fields = %w[geometry geojson]
    ignored_fields = stripped_fields + %w[updated_at]
    ids_to_delete = []
    ids_to_strip = []

    PaperTrail::Version.where(item_type: "Fmu", event: "update").find_each do |version|
      next if version.object_changes.blank?

      changes = YAML.unsafe_load(version.object_changes)
      next unless (changes.keys & stripped_fields).any?

      if (changes.keys - ignored_fields).empty?
        ids_to_delete << version.id
      else
        ids_to_strip << version.id
      end
    end

    puts "Found #{ids_to_delete.size} versions to delete (only ignored fields changed)."
    puts "Found #{ids_to_strip.size} versions to strip ignored fields from."

    if for_real
      if ids_to_delete.any?
        PaperTrail::Version.where(id: ids_to_delete).delete_all
        puts "Deleted #{ids_to_delete.size} versions."
      end

      if ids_to_strip.any?
        PaperTrail::Version.where(id: ids_to_strip).find_each do |version|
          changes = YAML.unsafe_load(version.object_changes)
          stripped_fields.each { |f| changes.delete(f) }
          version.update_column(:object_changes, PaperTrail.serializer.dump(changes))
        end
        puts "Stripped ignored fields from #{ids_to_strip.size} versions."
      end
    end
  end
end
