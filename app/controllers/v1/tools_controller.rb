# frozen_string_literal: true

module V1
  class ToolsController < APIController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: "Tool"
  end
end
