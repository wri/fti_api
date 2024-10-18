# frozen_string_literal: true

module V1
  class LawsController < APIController
    include APIUploads

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: "Law"
  end
end
