# frozen_string_literal: true

module V1
  class ImportsController < APIController
    authorize_resource :file_data_import

    def create
      importer.import(user_id_params.merge(importer_params))

      render json: importer.results
    end

    private

    def importer_type
      params.fetch(:importer_type)
    end

    def import_params
      params.fetch(:import).permit(:importer_type, :file, :importer_params)
    end

    def importer
      @importer ||= FileDataImport::BaseImporter.build(import_params[:importer_type], import_params[:file])
    end

    def importer_params
      JSON.parse(import_params[:importer_params] || {}).symbolize_keys
    end

    def user_id_params
      current_user ? {user_id: current_user.id} : {user_id: nil}
    end

    def set_locale(&action)
      I18n.with_locale(:en, &action)
    end
  end
end
