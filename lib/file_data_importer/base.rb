# frozen_string_literal: true

module FileDataImporter
  class Base
    class InvalidImporterError < NameError; end
    class InvalidParserError < NameError; end

    include ActiveModel::Validations

    ALLOWED_EXTENSIONS = %w[csv].freeze

    attr_reader :file, :results

    validates :extension, inclusion: { in: ALLOWED_EXTENSIONS }

    def initialize(file)
      @file = file
      @results = {}
    end

    def import
      parser.foreach_with_line do |attributes, line|
        results[line] = self.class.record_builder.save(attributes)
      end
    end

    protected

    def parser
      @parser ||= begin
        parser_name = "FileDataImporter::Parser::#{extension.capitalize}"
        parser_name.constantize.new(file.path)
      rescue NameError
        raise InvalidParserError, "Undefined parser #{importer_name}."
      end
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

      def belongs_to(record_class, permited_attributes = [], permited_translations = [])
        record_builder.belongs_to(record_class, permited_attributes, permited_translations)
      end
    end

    extend ClassMethods
  end
end
