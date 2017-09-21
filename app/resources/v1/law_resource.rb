module V1
  class LawResource < JSONAPI::Resource
    caching
    attributes :written_infraction, :infraction, :sanctions, :min_fine, :max_fine,
               :penal_servitude, :other_pernalties, :flegt

    has_one :subcategory
    has_one :country
    has_many   :observations

    def custom_links(_)
      { self: nil }
    end
  end
end
