class GeolocationService
  attr_accessor :reader

  AddressNotFoundError = Class.new(StandardError)

  def initialize
    @reader = MaxMind::GeoIP2::Reader.new(
      database: db_path.to_s
    )
  end

  def call(ip)
    reader.city(ip)
  rescue MaxMind::GeoIP2::AddressNotFoundError
    raise AddressNotFoundError
  end

  private

  def db_path
    # Test and dev DB taken from https://github.com/maxmind/MaxMind-DB/tree/main/test-data
    return Rails.root.join("db", "#{edition_id}-Test.mmdb") if Rails.env.test? || Rails.env.e2e?

    Rails.root.join("db", "#{edition_id}.mmdb")
  end

  def edition_id
    "GeoLite2-City"
  end
end
