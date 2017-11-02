module V1
  class SpeciesResource < JSONAPI::Resource
    caching

    attributes :common_name, :name, :species_class, :sub_species,
               :species_family, :species_kingdom, :scientific_name,
               :cites_status, :cites_id, :iucn_status

    has_many :countries

    def custom_links(_)
      { self: nil }
    end

    # Adds the locale to the cache
    def self.attribute_caching_context(context)
      return {
          locale: context[:locale]
      }
    end
  end
end
