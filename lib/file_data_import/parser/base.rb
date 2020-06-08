# frozen_string_literal: true

module FileDataImport
  module Parser
    class Base
      AVAILABLE_EXTENSIONS = %w[shp csv].freeze

      attr_reader :path_to_file

      def initialize(path_to_file)
        @path_to_file = path_to_file
      end

      def foreach_with_line
        raise NotImplementedError, "You need to implement foreach_with_line method."
      end
    end
  end
end
