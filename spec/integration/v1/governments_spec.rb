require "rails_helper"

module V1
  describe "Governments", type: :request do
    it_behaves_like "jsonapi-resources", Government, {
      show: {
        success_roles: %i[admin]
      },
      create: {
        success_roles: %i[admin ngo],
        failure_roles: %i[user],
        valid_params: {"government-entity": "Government one"},
        invalid_params: {"government-entity": ""},
        error_attributes: [422, 100, {"government-entity": ["can't be blank"]}]
      },
      edit: {
        success_roles: %i[admin ngo],
        failure_roles: %i[user],
        valid_params: {"government-entity": "Government one"},
        invalid_params: {"government-entity": ""},
        error_attributes: [422, 100, {"government-entity": ["can't be blank"]}]
      },
      delete: {
        success_roles: %i[admin],
        failure_roles: %i[user]
      },
      pagination: {
        success_roles: %i[admin]
      },
      sort: {
        success_roles: %i[admin],
        attribute: :government_entity,
        sequence: ->(i) { "#{i} government" }
      },
      filter: {
        success_roles: %i[admin],
        filters: [
          {attributes: {country_id: FactoryBot.create(:country).id}}
        ]
      }
    }

    context "filters" do
      describe "by observer_id" do
        let(:country) { create(:country) }
        let(:observer) { create(:observer) }
        let(:gov) { create(:government, country: country) }
        let(:user) { create(:ngo, observer: observer) }
        let(:headers) { authorize_headers(user.id) }

        before do
          create_list(:government, 3, country: country) # those should not be returned
          create(:gov_observation, observers: [observer], governments: [gov])
        end

        it "returns only governments linked with observer observations" do
          get "/governments?filter[observer_id]=#{observer.id}", headers: headers

          expect(status).to eq(200)
          expect(parsed_data.size).to eq(1)
          expect(parsed_data.first[:id].to_i).to eq(gov.id)
        end
      end
    end
  end
end
