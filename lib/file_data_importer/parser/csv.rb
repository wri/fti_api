# frozen_string_literal: true

module FileDataImporter
  module Parser
    class Csv < FileDataImporter::Parser::Base
      def foreach_with_line
        return unless block_given?

        CSV.foreach(path_to_file, headers: true, header_converters: :symbol).with_index(1) do |row, line|
          yield(row.to_h, line)
        end
      end
    end
  end
end
