# frozen_string_literal: true

module V1
  class SpeciesResource < BaseResource
    include CacheableByLocale
    caching

    attributes :common_name, :name, :species_class, :sub_species,
      :species_family, :species_kingdom, :scientific_name,
      :cites_status, :cites_id, :iucn_status

    has_many :countries
  end
end
