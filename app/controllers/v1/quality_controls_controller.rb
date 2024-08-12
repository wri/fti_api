# frozen_string_literal: true

module V1
  class QualityControlsController < APIController
    include ErrorSerializer

    load_and_authorize_resource class: "QualityControl"
  end
end
