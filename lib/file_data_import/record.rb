# frozen_string_literal: true

module FileDataImport
  class Record
    attr_reader :class_name, :permited_attributes, :permited_translations, :raw_attributes, :results

    def initialize(class_name, raw_attributes, **options)
      @class_name = class_name
      @raw_attributes = raw_attributes
      @permited_attributes = options[:permited_attributes] || []
      @permited_translations = options[:permited_translations] || []
      @belongs_to_associations = []
      @results = { attributes: {}, errors: {} }
    end

    def record
      @record ||= class_name.new
    end

    def belongs_to(association)
      @belongs_to_associations.push(association)
    end

    def save
      class_name.transaction do
        belongs_to_attributes =
          @belongs_to_associations.each_with_object({}) do |belongs_to_association, attributes|
            belongs_to_association.save
            singular_name = belongs_to_association.singular_name

            if belongs_to_association.errors.blank?
              attributes[singular_name] = belongs_to_association.record
            else
              results[:errors][singular_name] = belongs_to_association.errors
            end

            if belongs_to_association.attributes.present?
              results[:attributes][singular_name] = belongs_to_association.attributes
            end
          end

        record.assign_attributes(attributes_for_creation.merge(belongs_to_attributes))


        record.save
        results[:errors][:record] = record.errors.messages unless record.errors.empty?
        results[:attributes][:record] = attributes_for_finding
        raise ActiveRecord::RecordInvalid if results[:errors].any?
      end
    rescue ActiveRecord::RecordInvalid
      nil
    end

    private

    def attributes_for_creation
      @attributes_for_creation ||= begin
        extracted_attributes.merge({ translations_attributes: [translations_attributes.merge(locale: I18n.locale)] })
      end
    end

    def attributes_for_finding
      @attributes_for_finding ||= extracted_attributes.merge(translations_attributes)
    end

    def extracted_attributes
      @extracted_attributes ||= raw_attributes.slice(*permited_attributes).compact
    end

    def translations_attributes
      @translations_attributes ||= raw_attributes.slice(*permited_translations).compact
    end
  end
end
