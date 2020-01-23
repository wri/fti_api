require 'acceptance_helper'

module V1
  describe 'Donor', type: :request do
    let(:headers) do
      token = JWT.encode({ user: create(:webuser).id }, ENV['AUTH_SECRET'], 'HS256')

      {
        'Content-Type' => 'application/vnd.api+json',
        'HTTP_ACCEPT' => 'application/vnd.api+json',
        'HTTP_OTP_API_KEY' => "Bearer #{token}"
      }
    end

    describe 'Translateabale' do
      let!(:donor) do
        donor = create(:donor, name: 'Donor name en')
        donor.attributes = { name: 'Donor name fr', locale: :fr }
        donor.save
        donor
      end

      %i[en fr].each do |locale|
        it "Get for #{locale} locale" do
          get "/donors?locale=#{locale}", headers: headers

          expect(status).to eq(200)
          expect(json.first["attributes"]["name"]).to eq("Donor name #{locale}")
        end
      end
    end
  end
end
