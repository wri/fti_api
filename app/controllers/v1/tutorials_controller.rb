# frozen_string_literal: true

module V1
  class TutorialsController < APIController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: "Tutorial"
  end
end
