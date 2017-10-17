module V1
  class PartnersController < ApiController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Partner'
  end
end
