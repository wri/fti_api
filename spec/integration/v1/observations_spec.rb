require "rails_helper"

module V1
  describe "Observation", type: :request do
    it_behaves_like "jsonapi-resources", Observation, {
      show: {
        success_roles: %i[admin]
      },
      delete: {
        factory: :created_observation,
        success_roles: %i[admin],
        failure_roles: %i[user]
      }
      # pagination: { }
    }

    let(:ngo_observer) { create(:observer) }
    let(:ngo) { create(:ngo, observer: ngo_observer) }
    let(:ngo_headers) { authorize_headers(ngo.id) }
    let!(:country) { create(:country) }

    let(:observation) { create(:observation_1) }

    context "Show observations" do
      before do
        poland = create(:country, name: "Poland", iso: "POL")
        spain = create(:country, name: "Spain", iso: "ESP")
        create_list(:observation, 4, country: poland)
        create(:observation, observers: [ngo_observer], user_id: ngo.id, country: spain)
        create(:observation, observers: [ngo_observer], user_id: ngo.id, country: spain, fmu: create(:fmu))
        create(:gov_observation, user_id: admin.id, country: poland)
      end

      it "Get all observations list" do
        get "/observations", headers: webuser_headers
        expect(status).to eq(200)
        expect(parsed_data.size).to eq(7)
      end

      it "Get all observations and include relationships" do
        include = %w[operator subcategory subcategory.category observers governments law.country fmu severity]
        get "/observations?include=#{include.join(",")}", headers: webuser_headers
        expect(status).to eq(200)
        expect(parsed_data.size).to eq(7)
        included_types = parsed_body[:included].pluck(:type).uniq
        expect(included_types).to include("countries")
        expect(included_types).to include("operators")
        expect(included_types).to include("subcategories")
        expect(included_types).to include("governments")
        expect(included_types).to include("categories")
        expect(included_types).to include("observers")
        expect(included_types).to include("fmus")
        expect(included_types).to include("laws")
        expect(included_types).to include("severities")
        # jsonapi resources in newer version has problems with including nested relations
        law = parsed_body[:included].find { |obj| obj[:type] == "laws" }
        expect(law[:relationships][:country][:data]).to be_present

        subcategory = parsed_body[:included].find { |obj| obj[:type] == "subcategories" }
        expect(subcategory[:relationships][:category][:data]).to be_present
      end

      context "Observations tool" do
        it "Get owned observations list" do
          get "/observations", params: {app: "observations-tool"}, headers: ngo_headers
          expect(status).to eq(200)
          expect(parsed_data.size).to eq(2)
        end
      end
    end

    context "Create observations" do
      describe "For admin user" do
        it "Returns error object when the observation cannot be created by admin" do
          post("/observations",
            params: jsonapi_params("observations", nil, {"country-id": "", "observation-type": "operator", "publication-date": DateTime.now}),
            headers: admin_headers)

          expect(parsed_body).to eq(jsonapi_errors(422, 100, {relationships_country: ["must exist"]}))
          expect(status).to eq(422)
        end

        it "Returns success object when the observation was successfully created by admin" do
          params = {"country-id": country.id, "observation-type": "operator", "publication-date": DateTime.now, lat: 123.4444, lng: 12.4444}

          post("/observations",
            params: jsonapi_params("observations", nil, params),
            headers: admin_headers)

          expect(parsed_data[:id]).not_to be_empty
          params.except(:"publication-date", :lat, :lng).each do |name, value|
            expect(parsed_attributes[name]).to eq(value)
          end
          expect(parsed_attributes[:lat]).to eq(params[:lat].to_s)
          expect(parsed_attributes[:lng]).to eq(params[:lng].to_s)
          expect(status).to eq(201)
        end
      end

      describe "For not admin user" do
        it "Do not allows to create observation by not admin user" do
          post("/observations",
            params: jsonapi_params("observations", nil, {"country-id": country.id}),
            headers: user_headers)

          expect(parsed_body).to eq(default_status_errors(401))
          expect(status).to eq(401)
        end
      end
    end

    context "Edit observations" do
      let(:observation) { create(:observation_1) }

      describe "For admin user" do
        it "Returns error object when the observation cannot be updated by admin" do
          patch("/observations/#{observation.id}?app=observations-tool",
            params: jsonapi_params("observations", observation.id, {"country-id": ""}),
            headers: admin_headers)

          expect(parsed_body).to eq(jsonapi_errors(422, 100, {relationships_country: ["must exist"]}))
          expect(status).to eq(422)
        end

        it "Returns success object when the observation was successfully updated by admin" do
          patch("/observations/#{observation.id}?app=observations-tool",
            params: jsonapi_params("observations", observation.id, {"is-active": false}),
            headers: admin_headers)

          expect(parsed_attributes[:"is-active"]).to eq(false)
          expect(observation.reload.deactivated?).to eq(true)
          expect(status).to eq(200)
        end

        it "Returns success object when the observation was successfully deactivated by admin" do
          patch("/observations/#{observation.id}?app=observations-tool",
            params: jsonapi_params("observations", observation.id, {"is-active": false}),
            headers: admin_headers)

          expect(observation.reload.is_active).to eq(false)
          expect(status).to eq(200)
        end

        xit "Allows to translate observation" do
          patch("/observations/#{observation.id}?locale=fr&app=observations-tool",
            params: jsonapi_params("observations", observation.id, {details: "FR Observation one"}),
            headers: admin_headers)

          expect(observation.reload.details).to eq("FR Observation one")
          I18n.with_locale(:en) do
            expect(observation.reload.details).to eq("00 Observation one")
          end
          expect(status).to eq(200)
        end
      end

      describe "For not admin user" do
        let(:observation_by_user) { create(:observation_1, validation_status: "Published (no comments)", user_id: ngo.id) }

        it "Do not allows to update observation by not admin user" do
          patch("/observations/#{observation.id}?app=observations-tool",
            params: jsonapi_params("observations", observation.id, {name: "Observation one"}),
            headers: ngo_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
        end

        it "Do not allows to deactivate observation by user" do
          patch("/observations/#{observation_by_user.id}?app=observations-tool",
            params: jsonapi_params("observations", observation_by_user.id, {"is-active": false}),
            headers: webuser_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
          expect(observation_by_user.reload.deactivated?).to eq(false)
        end
      end

      describe "For all users" do
        describe "Modify status" do
          it "Status goes from Created to Ready for QC" do
            patch("/observations/#{observation.id}?app=observations-tool",
              params: jsonapi_params("observations", observation.id, {"validation-status": "Ready for QC"}),
              headers: admin_headers)
            expect(status).to eq(200)
            expect(parsed_body[:data][:attributes][:"validation-status"]).to eq("Ready for QC")
          end

          it "Status cannot go to Needs revision" do
            patch("/observations/#{observation.id}?app=observations-tool",
              params: jsonapi_params("observations", observation.id, {"validation-status": "Needs revision"}),
              headers: admin_headers)

            expect(parsed_body[:errors].first[:title]).to eq("Invalid validation change for monitor. Can't move from 'Created' to 'Needs revision'")
            expect(status).to eq(422)
          end
        end
      end
    end
  end
end
