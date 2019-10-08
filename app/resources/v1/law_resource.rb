# frozen_string_literal: true

module V1
  class LawResource < JSONAPI::Resource
    caching
    attributes :written_infraction, :infraction, :sanctions, :min_fine, :max_fine,
               :penal_servitude, :other_penalties, :apv, :complete, :currency

    has_one :subcategory
    has_one :country
    has_many   :observations

    filters :country, :subcategory, :written_infraction, :infraction, :sanctions, :min_fine, :max_fine,
            :penal_servitude, :other_penalties, :apv

    filter :complete, apply: -> (records, value, _options) {
      if value[0] == "true"
        records.where('written_infraction is not null and infraction is not null and
sanctions is not null and min_fine is not null and max_fine is not null and penal_servitude is not null
and apv is not null and currency is not null')
      else
        records.where('written_infraction is null or infraction is null or
sanctions is null or min_fine is null or max_fine is null or penal_servitude is null
or apv is null or currency is null')
      end
    }

    def self.sortable_fields(context)
      super + [:'subcategory.name', :'country.name']
    end

    # When ordering by a translated table in a belongs_to relationship
    # we add the ordering by id to ensure that when limiting by 1 or 100
    # the order of the results is the same
    def self.apply_sort(records, order_options, context = {})
      if order_options['country.name'].present? || order_options['subcategory.name'].present?
        order_options['id'] =  'DESC'
      end
      super(records, order_options, context)
    end

    def complete
      @model.written_infraction.present? &&
          @model.infraction.present? &&
          @model.sanctions.present? &&
          @model.min_fine.present? &&
          @model.max_fine.present? &&
          @model.penal_servitude.present? &&
          @model.apv.present? &&
          @model.currency.present?
    end

    def custom_links(_)
      { self: nil }
    end
  end
end
