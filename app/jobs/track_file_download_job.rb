class TrackFileDownloadJob < ApplicationJob
  queue_as :default

  def perform(client_id, client_ip, source, source_info, file_url, file_name, model_name)
    return if measurement_id.blank? || api_secret.blank?

    location = get_location_details(client_ip)
    send_ga4_event(client_id, location, source, source_info, file_url, file_name, model_name)
  end

  private

  def get_location_details(client_ip)
    result = GeolocationService.new.call(client_ip)

    {
      country: result.country&.name,
      country_code: result.country&.iso_code,
      city: result.city&.name,
      region: result.subdivisions.first&.name
    }
  rescue GeolocationService::AddressNotFoundError
    {country: nil, city: nil, region: nil, country_code: ""}
  end

  def send_ga4_event(client_id, location, source, source_info, file_url, file_name, model_name)
    payload = {
      client_id: client_id,
      events: [{
        name: "server_file_download",
        params: {
          file_name: file_name,
          file_extension: File.extname(file_name).downcase.delete("."),
          file_url: file_url,
          link_url: file_url,
          model_name: model_name,
          country: location[:country],
          country_code: location[:country_code],
          region: location[:region],
          city: location[:city],
          source: source,
          source_info: source_info
        }.compact
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
