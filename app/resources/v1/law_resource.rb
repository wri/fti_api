module V1
  class LawResource < JSONAPI::Resource
    caching
    attributes :written_infraction, :infraction, :sanctions, :min_fine, :max_fine,
               :penal_servitude, :other_penalties, :apv

    has_one :subcategory
    has_one :country
    has_many   :observations

    filters :country, :subcategory, :written_infraction, :infraction, :sanctions, :min_fine, :max_fine,
            :penal_servitude, :other_penalties, :apv

    def self.sortable_fields(context)
      super + [:'subcategory.name', :'country.name']
    end

    def custom_links(_)
      { self: nil }
    end
  end
end
