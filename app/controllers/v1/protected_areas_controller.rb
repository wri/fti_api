module V1
  class ProtectedAreasController < APIController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:tiles]

    def tiles
      tile = ProtectedArea.vector_tiles params[:z], params[:x], params[:y]
      send_data tile
    end
  end
end
