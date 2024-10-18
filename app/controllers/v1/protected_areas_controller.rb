module V1
  class ProtectedAreasController < APIController
    skip_before_action :authenticate, only: [:tiles]

    def tiles
      send_data ProtectedAreaVectorTile.fetch params[:x], params[:y], params[:z]
    end
  end
end
