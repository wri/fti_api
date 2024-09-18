# frozen_string_literal: true

module V1
  class ObserversController < APIController
    include ErrorSerializer
    include APIUploads

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: "Observer"
  end
end
