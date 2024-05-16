# frozen_string_literal: true

module V1
  class NewslettersController < APIController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index]
    load_and_authorize_resource class: "Newsletter"
  end
end
