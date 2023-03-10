# frozen_string_literal: true

module V1
  class ObservationReportsController < APIController

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'ObservationReport'

  end
end
