require "rails_helper"

module V1
  describe "Operator", type: :request do
    let(:country) { create(:country) }
    let(:existing_operator) { create(:operator, name: "Existing") }

    it_behaves_like "jsonapi-resources", Operator, {
      show: {},
      create: {
        success_roles: %i[admin user webuser],
        failure_roles: [],
        valid_params: -> { {name: "Operator one", "operator-type": "Other", relationships: {country: country.id}} },
        invalid_params: -> { {name: existing_operator.name.downcase, "operator-type": "Other"} },
        error_attributes: [422, 100, {name: ["has already been taken"], relationships_country: ["can't be blank"]}],
        expect_on_success: -> {
          expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with("SystemMailer", "operator_created", "deliver_now", {args: [Operator.last]})
        }
      },
      edit: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: {name: "Operator one", "operator-type": "Other"},
        invalid_params: {name: "", "operator-type": "Other"},
        error_attributes: [422, 100, {name: ["can't be blank"]}]
      },
      delete: {
        success_roles: %i[admin],
        failure_roles: %i[user]
      },
      pagination: {},
      sort: {
        attribute: :name,
        sequence: ->(i) { "#{i} operator" }
      }
    }

    context "Edit operators" do
      let(:photo_data) do
        "data:image/jpeg;base64,#{Base64.encode64(File.read(File.join(Rails.root, "spec", "support", "files", "image.png")))}"
      end

      let(:operator) { create(:operator) }

      describe "For admin user" do
        it "Upload logo and returns success object when the operator was successfully updated by admin" do
          patch("/operators/#{operator.id}",
            params: jsonapi_params("operators", operator.id, {logo: photo_data}),
            headers: admin_headers)

          expect(status).to eq(200)
          expect(parsed_attributes[:logo]).to_not be_empty
          expect(parsed_attributes.dig(:logo, :url)).to include("operator/logo/#{operator.id}/logo.png")
        end

        context "when the operator has details" do
          let(:operator) { create(:operator, details: "Some details") }

          it "forces re-translations from the locale of the request when details change" do
            expect(TranslationJob).to receive(:perform_later).with(operator, :fr)

            patch("/operators/#{operator.id}?locale=fr",
              params: jsonapi_params("operators", operator.id, {details: "Nouveaux details"}),
              headers: admin_headers)

            expect(status).to eq(200)
          end

          it "does not force re-translations when details are unchanged" do
            expect(TranslationJob).to_not receive(:perform_later)

            patch("/operators/#{operator.id}?locale=fr",
              params: jsonapi_params("operators", operator.id, {details: operator.details, name: "New name"}),
              headers: admin_headers)

            expect(status).to eq(200)
          end
        end
      end
    end

    describe "Rate limiting" do
      def create_operator(name)
        post "/operators",
          params: jsonapi_params("operators", nil, {
            name: name,
            "operator-type": "Other",
            relationships: {country: country.id}
          }),
          headers: jsonapi_headers
      end

      it "Allows 5 operator creations per IP per hour" do
        5.times do |i|
          create_operator("Public operator #{i}")
          expect(status).to eq(201)
        end
      end

      it "Throttles a 6th operator creation from the same IP" do
        5.times { |i| create_operator("Public operator #{i}") }

        create_operator("Blocked operator")

        expect(status).to eq(429)
        expect(parsed_body).to eq({errors: [{status: 429, title: "Too many requests"}]})
      end
    end

    context "filters" do
      describe "by observer_id" do
        let(:observer) { create(:observer) }
        let(:user) { create(:ngo, observer: observer) }
        let(:operator) { create(:operator, country: country) }
        let(:headers) { authorize_headers(user.id) }

        before do
          create_list(:operator, 3, country: country) # those should not be returned
          create(:observation, operator: operator, observation_report: create(:observation_report, observers: [observer]))
        end

        it "returns only operators linked with observer observations" do
          get "/operators?filter[observer_id]=#{observer.id}", headers: headers

          expect(status).to eq(200)
          expect(parsed_data.size).to eq(1)
          expect(parsed_data.first[:id].to_i).to eq(operator.id)
        end
      end
    end
  end
end
