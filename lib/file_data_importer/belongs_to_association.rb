# frozen_string_literal: true

module FileDataImporter
  class BelongsToAssociation
    attr_accessor :class_name, :permited_attributes, :permited_translations

    def initialize(class_name, permited_attributes = [], permited_translations = [])
      @class_name = class_name
      @permited_attributes = permited_attributes
      @permited_translations = permited_translations
    end

    def singular_name
      class_name.model_name.singular
    end

    def attributes_for_result
      @attributes_for_result ||= [:id] + permited_attributes + permited_translations
    end

    def attributes
      association.attributes.symbolize_keys.slice(*attributes_for_result)
    end

    def association(attributes = {})
      @association ||= begin
        all_attributes = find_all_attributes(attributes)
        association_attributes = extract_attributes(all_attributes)
        translation_attributes = extract_translations(all_attributes)
        association = class_name.find_by(association_attributes.merge(translation_attributes))

        return association if association

        class_name.new(association_attributes.merge({
          translations_attributes: [translation_attributes.merge(locale: I18n.locale)]
        }))
      end
    end

    private

    def find_all_attributes(attributes)
      normalized_attributes = {}

      (permited_attributes + permited_translations).each do |attribute|
        attr_key = "#{singular_name}__#{attribute}".to_sym

        next if attributes[attr_key].blank?

        normalized_attributes[attribute] = attributes[attr_key]
      end

      normalized_attributes
    end

    def extract_attributes(attributes)
      attributes.slice(*permited_attributes)
    end

    def extract_translations(attributes)
      attributes.slice(*permited_translations)
    end
  end
end
