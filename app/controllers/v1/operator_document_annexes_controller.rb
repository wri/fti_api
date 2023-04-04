# frozen_string_literal: true

module V1
  class OperatorDocumentAnnexesController < APIController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: "OperatorDocumentAnnex"
  end
end
