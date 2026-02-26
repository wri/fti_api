PAPER_TRAIL_CLEAN_CONFIG = [
  {
    item_type: "Operator",
    stripped_fields: %w[
      percentage_valid_documents_all
      percentage_valid_documents_fmu
      percentage_valid_documents_country
      country_doc_rank
      country_operators
    ]
  },
  {
    item_type: "Fmu",
    stripped_fields: %w[geometry geojson]
  }
].freeze

namespace :paper_trail do
  desc "Clean versions for all models - delete where only ignored fields changed, strip those fields from the rest. Set FOR_REAL=true to apply."
  task clean_up: :environment do
    for_real = ENV["FOR_REAL"] == "true"

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN (set FOR_REAL=true to apply changes)"

    PAPER_TRAIL_CLEAN_CONFIG.each do |config|
      item_type = config[:item_type]
      stripped_fields = config[:stripped_fields]
      ignored_fields = stripped_fields + %w[updated_at]
      ids_to_delete = []
      ids_to_strip = []

      PaperTrail::Version.where(item_type: item_type, event: "update").find_each do |version|
        next if version.object_changes.blank?

        changes = version.changeset
        next unless (changes.keys & stripped_fields).any?

        if (changes.keys - ignored_fields).empty?
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
end
