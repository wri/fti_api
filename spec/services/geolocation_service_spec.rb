require "rails_helper"

RSpec.describe GeolocationService do
  it "returns country code if IP found" do
    # available test data here https://github.com/maxmind/MaxMind-DB/blob/main/source-data/GeoLite2-Country-Test.json
    result = GeolocationService.new.call("81.2.69.142")

    expect(result).not_to be_nil
    expect(result.country.name).to eq("United Kingdom")
    expect(result.country.iso_code).to eq("GB")
  end

  it "raises exception if IP not found" do
    expect { GeolocationService.new.call("3.2.4.142") }.to raise_error(GeolocationService::AddressNotFoundError)
  end
end
