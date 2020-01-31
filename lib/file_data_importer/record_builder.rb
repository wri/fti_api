# frozen_string_literal: true

module FileDataImporter
  class RecordBuilder
    attr_accessor :class_name, :permited_attributes, :permited_translations
    attr_reader :belongs_to_associations

    def initialize(class_name = nil, permited_attributes = [], permited_translations = [])
      @class_name = class_name
      @permited_attributes = permited_attributes
      @permited_translations = permited_translations
      @belongs_to_associations = []
    end

    def attributes_for_result
      @attributes_for_result ||= [:id] + permited_attributes + permited_translations
    end

    def belongs_to(class_name, permited_attributes = [], permited_translations = [])
      association = BelongsToAssociation.new(class_name, permited_attributes, permited_translations)
      belongs_to_associations.push(association)
    end

    def save(attributes = {})
      record_attributes = extract_attributes(attributes)
      translations = extract_translations(attributes)
      associations = build_associations(attributes)
      # move to record class
      record = class_name.new(record_attributes.merge(translations))

      class_name.transaction do
        associations.each_value { |association| association.save unless association.persisted? }
        record.assign_attributes(associations)
        record.save
      end

      build_result(record, associations)
    end

    def build_result(record, associations)
      errors = build_errors(record, associations)
      attributes = build_result_attributes(record)

      { attributes: attributes, errors: errors }
    end

    def build_result_attributes(record)
      attributes = {}
      attributes[:record] = record.attributes.symbolize_keys.slice(*attributes_for_result)

      belongs_to_associations.each do |association|
        attributes[association.singular_name.to_sym] = association.attributes
      end

      attributes
    end

    def build_errors(record, associations)
      errors = {}
      errors[:record] = record.errors.messages if record.errors.any?

      associations.each do |name, association|
        errors[name] = association.errors.messages if association.errors.any?
      end

      errors
    end

    def build_associations(attributes = {})
      associations = {}

      belongs_to_associations.each do |association|
        next if attributes["#{association.singular_name}_id".to_sym].present?

        associations[association.singular_name.to_sym] = association.association(attributes)
      end

      associations
    end

    private

    def extract_attributes(attributes)
      attributes.slice(*permited_attributes).compact
    end

    def extract_translations(attributes)
      normalized_attributes = attributes.slice(*permited_translations).compact

      { translations_attributes: [normalized_attributes.merge(locale: I18n.locale)] }
    end
  end
end
