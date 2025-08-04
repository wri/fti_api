class TrackDownloadJob < ApplicationJob
  queue_as :default

  def perform(file_url, file_name, model_name)
    return if measurement_id.blank? || api_secret.blank?

    send_ga4_event(file_url, file_name, model_name)
  end

  private

  def send_ga4_event(file_url, file_name, model_name)
    payload = {
      events: [{
        name: "file_download",
        params: {
          file_name: file_name,
          file_extension: File.extname(file_name).downcase.delete("."),
          file_url: file_url,
          link_url: file_url,
          model_name: model_name
        }
      }]
    }

    HTTP.post(
      "https://www.google-analytics.com/mp/collect",
      params: {
        measurement_id: measurement_id,
        api_secret: api_secret
      },
      json: payload
    )
  end

  def measurement_id
    ENV["GA4_MEASUREMENT_ID"]
  end

  def api_secret
    ENV["GA4_API_SECRET"]
  end
end
