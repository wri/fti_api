# frozen_string_literal: true

module V1
  class ImportsController < ApiController
    # before action => check if importer present
    def create
      importer.import

      render json: importer.results
    end

    private

    def importer_type
      params.fetch(:importer_type)
    end

    def import_params
      params.fetch(:import).permit(:importer_type, :file)
    end

    def importer
      @importer ||= FileDataImporter::Base.build(import_params.symbolize_keys)
    end
  end
end
