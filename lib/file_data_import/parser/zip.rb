# frozen_string_literal: true

require "zip"

module FileDataImport
  module Parser
    class Zip < FileDataImport::Parser::Base
      class InvalidZipContent < NameError; end

      def extract_zip
        FileUtils.mkdir_p(folder_path)

        ::Zip::File.open(path_to_file) do |zip_file|
          zip_file.each do |file|
            file_path = File.join(folder_path, file.name)
            zip_file.extract(file, file_path)
          end
        end
      end

      def folder_path
        @folder_path ||= Dir.mktmpdir
      end

      def parser
        @parser ||= begin
          parser_name = "FileDataImport::Parser::#{extracted_file_extname.capitalize}"
          parser_name.constantize.new(path_to_extracted_file)
        end
      end

      def path_to_extracted_file
        @path_to_extracted_file ||= begin
          path = AVAILABLE_EXTENSIONS.find do |ext|
            path = Dir[File.join(folder_path, "*.#{ext}")].first
            break path if path.present?
          end

          return path if path.present?

          raise InvalidZipContent, "No such files to import"
        end
      end

      def extracted_file_extname
        @extracted_file_extname = File.extname(path_to_extracted_file)[1..]
      end

      def foreach_with_line(&block)
        return unless block

        extract_zip
        parser.foreach_with_line(&block)

        clean_up_files
      end

      def clean_up_files
        File.delete(path_to_file) if File.exist?(path_to_file)
        FileUtils.remove_dir(folder_path) if File.directory?(folder_path)
      end
    end
  end
end
