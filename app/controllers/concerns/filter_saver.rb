# frozen_string_literal: true

module FilterSaver
  # rubocop:disable Style/AsciiComments
  # Extends the ActiveAdmin controller to persist resource index filters between requests.
  #
  # @author David Daniell / тιηуηυмвєяѕ <info@tinynumbers.com>
  # rubocop:enable Style/AsciiComments
  SAVED_FILTER_KEY = :last_search_filter

  private

  def restore_search_filters
    filter_storage = session[SAVED_FILTER_KEY]
    if params[:clear_filters].present?
      params.delete :clear_filters
      if filter_storage
        logger.info "clearing filter storage for #{controller_key}"
        filter_storage.delete controller_key
      end
      if request.post?
        # we were requested via an ajax post from our custom JS
        # this render will abort the request, which is ok, since a GET request will immediately follow
        render json: {filters_cleared: true}
      end
    elsif filter_storage && (params[:action].to_sym == :index) && params[:q].blank? && (params[:commit] != "Filter")
      saved_filters = filter_storage[controller_key]
      if saved_filters.present?
        params[:q] = saved_filters
      end
    end
  end

  def save_search_filters
    if params[:action].to_sym == :index
      session[SAVED_FILTER_KEY] ||= {}
      session[SAVED_FILTER_KEY][controller_key] = params[:q]
    end
  end

  # Get a symbol for keying the current controller in the saved-filter session storage.
  def controller_key
    current_path = request.env["PATH_INFO"]
    current_route = Rails.application.routes.recognize_path(current_path)
    current_route.sort.flatten.join("-").tr("/", "_")
  end
end
