module V1
  class LawResource < JSONAPI::Resource
    caching
    attributes :written_infraction, :infraction, :sanctions, :min_fine, :max_fine,
               :penal_servitude, :other_penalties, :apv, :complete

    has_one :subcategory
    has_one :country
    has_many   :observations

    filters :country, :subcategory, :written_infraction, :infraction, :sanctions, :min_fine, :max_fine,
            :penal_servitude, :other_penalties, :apv

    def self.sortable_fields(context)
      super + [:'subcategory.name', :'country.name']
    end

    def complete
      @model.written_infraction.present? &&
          @model.infraction.present? &&
          @model.sanctions.present? &&
          @model.min_fine.present? &&
          @model.max_fine.present? &&
          @model.penal_servitude.present? &&
          @model.apv.present?
    end


      #  written_infraction :text
      #  infraction         :text
      #  sanctions          :text
      #  min_fine           :integer
      #  max_fine           :integer
      #  penal_servitude    :string
      #  other_penalties    :text
      #  apv                :text
      #  subcategory_id     :integer
      #  created_at         :datetime         not null
      #  updated_at         :datetime         not null
      #  country_id         :integer

    def custom_links(_)
      { self: nil }
    end
  end
end
