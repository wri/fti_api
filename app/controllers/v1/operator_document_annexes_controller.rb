# frozen_string_literal: true

module V1
  class OperatorDocumentAnnexesController < APIController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: "OperatorDocumentAnnex", except: [:create] # authorize create action in base_resource before_save
  end
end
