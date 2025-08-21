class TrackFileDownloadJob < ApplicationJob
  queue_as :default

  def perform(client_id, client_ip, file_url, file_name, model_name)
    return if measurement_id.blank? || api_secret.blank?

    location = get_location_details(client_ip)
    send_ga4_event(client_id, location, file_url, file_name, model_name)
  end

  private

  def get_location_details(client_ip)
    # Cache to avoid repeated API calls
    Rails.cache.fetch("location_#{client_ip}", expires_in: 1.day) do
      result = Geocoder.search(client_ip).first

      if result
        {
          country: find_country_name_if_iso_provided(result.country, result.country_code),
          country_code: result.country_code,
          city: result.city,
          region: result.state
        }
      else
        {country: nil, city: nil, region: nil, country_code: ""}
      end
    end
  end

  def find_country_name_if_iso_provided(country_name, country_code)
    return country_name if country_name != country_code

    country = ISO3166::Country[country_code]
    return country_name if country.nil?

    country.common_name
  end

  def send_ga4_event(client_id, location, file_url, file_name, model_name)
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
          city: location[:city]
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
