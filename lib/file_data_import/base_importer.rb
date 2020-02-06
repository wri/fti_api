# frozen_string_literal: true

module FileDataImport
  class BaseImporter
    class InvalidImporterError < NameError; end
    class InvalidParserError < NameError; end

    attr_reader :file, :results

    def initialize(file)
      @file = file
      @results = {}
    end

    def import
      parser.foreach_with_line do |attributes, line|
        record = self.class.record_builder.build(attributes)
        record.save
        results[line] = record.results
      end
    end

    protected

    def parser
      @parser ||= begin
        parser_name = "FileDataImport::Parser::#{extension.capitalize}"
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
      def build(importer_type, file)
        importer_name = "#{importer_type.capitalize}Importer"
        importer_name.constantize.new(file)
      rescue NameError
        raise InvalidImporterError, "Undefined importer #{importer_name}."
      end

      def record(class_name, **options)
        record_builder.record(class_name, options)
      end

      def record_builder
        @record_builder ||= RecordBuilder.new
      end

      def belongs_to(class_name, **options)
        record_builder.belongs_to(class_name, options)
      end
    end

    extend ClassMethods
  end
end
