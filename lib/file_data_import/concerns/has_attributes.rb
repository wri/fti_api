# frozen_string_literal: true

module FileDataImport
  module Concerns
    module HasAttributes
      extend ActiveSupport::Concern

      def record_attributes
        return unless record
        record.attributes.symbolize_keys.slice(*attributes_for_serializing)
      end

      private

      def attributes_for_serializing
        @attributes_for_serializing ||= [:id] + permitted_attributes + permitted_translations
      end

      def attributes_for_creation
        @attributes_for_creation ||= begin
          return extracted_attributes if translations_attributes.blank?
          extracted_attributes.merge({ translations_attributes: [translations_attributes.merge(locale: I18n.locale)] })
        end
      end

      def attributes_for_finding
        @attributes_for_finding ||= extracted_attributes.merge(translations_attributes)
      end

      def extracted_attributes
        @extracted_attributes ||= raw_attributes.slice(*permitted_attributes).compact
      end

      def translations_attributes
        @translations_attributes ||= raw_attributes.slice(*permitted_translations).compact
      end
    end
  end
end
