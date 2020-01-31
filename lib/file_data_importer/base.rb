# frozen_string_literal: true

module FileDataImporter
  class Base
    include ActiveModel::Validations

    ALLOWED_EXTENSIONS = %w[csv].freeze

    attr_reader :file, :results

    validates :extension, inclusion: { in: ALLOWED_EXTENSIONS }

    def initialize(file)
      @file = file
      @results = []
    end

    def import
      parser.foreach_with_line do |attributes, line|
        # associations = build_associations(attributes) #self.class.belongs_to_associations.
        # result = self.class.record_builder.save(attributes)
        results << self.class.record_builder.save(attributes)
        # save_record(record, associations, line)
      end
    end

    protected

    def build_associations(attributes)
      associations = {}

      self.class.belongs_to_associations.each do |record_class, permited_attributes|
        record_singular_name = record_class.model_name.singular
        prefixed_attribute_names = permited_attributes.map { |name| "#{record_singular_name}__#{name}".to_sym }
        record_attributes = attributes.slice(*prefixed_attribute_names).transform_keys { |k| k.to_s.match(/__(\w+)/)[1].to_sym }

        next if record_attributes.blank?

        associations[record_singular_name.to_sym] = record_class.new(record_attributes)
      end

      associations
    end

    def parser
      @parser ||= begin
        parser_name = "FileDataImporter::Parser::#{extension.capitalize}"
        parser_name.constantize.new(file.path)
      rescue NameError
        raise InvalidParserError, "Undefined parser #{importer_name}."
      end
    end

    def save_record(record, associations, line)
      record.transaction do
        associations.each do |name, association|
          next if record.public_send("#{name}_id").present?
          association.save
          record.send(name, association)
        end

        record.save!
      end


      # return if record.save

      # errored_records.push({ line: line, errors: record.errors.messages })
    end

    def extension
      @extension ||= File.extname(basename)[1..-1]
    end

    def basename
      @basename ||= file.original_filename
    end

    module ClassMethods
      def build(importer_type:, file:)
        importer_name = "#{importer_type.capitalize}Importer"
        importer_name.constantize.new(file)
      rescue NameError
        raise InvalidImporterError, "Undefined importer #{importer_name}."
      end

      def define_record(class_name, permited_attributes = [], permited_translations = [])
        record_builder.class_name = class_name
        record_builder.permited_attributes = permited_attributes
        record_builder.permited_translations = permited_translations
      end

      def record_builder
        @record_builder ||= RecordBuilder.new
      end

      def belongs_to(record_class, permited_attributes: [] , permited_translations: [])
        record_builder.belongs_to(record_class, permited_attributes, permited_translations)
      end
    end

    extend ClassMethods
  end
end
