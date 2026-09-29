module V1
  class ProtectedAreasController < APIController
    skip_before_action :authenticate, only: [:tiles]

    def tiles
      expires_in 1.day, public: true, stale_while_revalidate: 1.week
      send_data ProtectedAreaVectorTile.fetch(params[:x], params[:y], params[:z]),
        type: "application/vnd.mapbox-vector-tile", disposition: "inline"
    end
  end
end
