require 'rails_helper'

module V1
  describe 'Observation', type: :request do
    it_behaves_like "jsonapi-resources", Observation, {
      show: {
        success_role: :admin
      },
      delete: {
        success_role: :admin,
        failure_role: :user
      },
      pagination: { }
    }

    let(:ngo) { create(:ngo) }
    let(:ngo_headers) { authorize_headers(create(:ngo).id) }
    let!(:country) { create(:country) }

    let!(:observation) { create(:observation_1, evidence: '00 Observation one') }

    context 'Show observations' do
      let!(:observations) {
        observations = []
        observations << create_list(:observation, 4)
        observations << create(:observation, evidence: 'ZZZ Next first one', user_id: ngo.id)
        observations << create(:observation, evidence: 'AAA Next first one', user_id: ngo.id)
        observations << create(:observation, evidence: '00 Observation one', user_id: admin.id)
      }

      describe 'Filter opbservations by user' do
        let(:ngo_headers) { authorize_headers(create(:ngo).id) }

        it 'Get all observations by specific user' do
          get '/observations', params: { user: admin.id }, headers: webuser_headers
          expect(status).to eq(200)
          expect(parsed_data.size).to eq(1)
        end

        it 'Get owned observations list' do
          get '/observations', params: { user: 'current' }, headers: ngo_headers
          expect(status).to eq(200)
          expect(parsed_data.size).to eq(2)
        end

        it 'Get all observations list' do
          get '/observations', params: { user: 'not' }, headers: webuser_headers
          expect(status).to eq(200)
          expect(parsed_data.size).to eq(8)
        end
      end
    end

    context 'Pagination and sort for observations' do
      let!(:country) { create(:country, name: 'Spain') }

      let!(:observations) {
        observations = []
        observations << create_list(:observation_2, 4)
        observations << create(:observation_1, evidence: 'ZZZ Next first one Spain', country: country)
      }

      let(:country_id) { Observation.find_by(evidence: 'ZZZ Next first one Spain').country.id }

      it 'Show list of observations for first page with per pege param' do
        get '/observations?page[number]=1&page[size]=3', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(3)
      end

      it 'Show list of observations for second page with per pege param' do
        get '/observations?page[number]=2&page[size]=3', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(3)
      end

      it 'Show list of observations for sort by evidence' do
        get '/observations?sort=evidence', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(6)
        expect(parsed_data[0][:attributes][:evidence]).to eq('00 Observation one')
      end

      it 'Show list of observations for sort by evidence DESC' do
        get '/observations?sort=-evidence', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(6)
        expect(parsed_data[0][:attributes][:evidence]).to eq('ZZZ Next first one Spain')
      end

      it 'Filter by operator' do
        get '/observations?type=operator', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(2)
        expect(parsed_data[0][:attributes][:evidence]).to eq('00 Observation one')
      end

      it 'Filter by governance' do
        get '/observations?type=governance', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(4)
        expect(parsed_data[0][:attributes][:evidence]).to eq('Governance observation')
      end

      it 'Filter observations by country and sort by illegality ASC' do
        get "/observations?country=#{country_id}&sort=illegality", headers: webuser_headers

        expect(status).to                            eq(200)
        expect(parsed_data.size).to                         eq(1)
        expect(parsed_data[0][:attributes][:evidence]).to match('Spain')
      end
    end

    context 'Create observations' do
      describe 'For admin user' do
        it 'Returns error object when the observation cannot be created by admin' do
          post('/observations',
               params: jsonapi_params('observations', nil, { 'country-id': '', 'observation-type': 'operator', 'publication-date': DateTime.now }),
               headers: admin_headers)

          expect(parsed_body).to eq(jsonapi_errors(422, 100, { 'country-id': ["can't be blank"] }))
          expect(status).to eq(422)
        end

        it 'Returns success object when the observation was seccessfully created by admin' do
          params = { 'country-id': country.id, 'observation-type': 'operator', 'publication-date': DateTime.now, lat: 123.4444, lng: 12.4444 }

          post('/observations',
               params: jsonapi_params('observations', nil, params),
               headers: admin_headers)

          expect(parsed_data[:id]).not_to be_empty
          params.except(:'publication-date').each do |name, value|
            expect(parsed_attributes[name]).to eq(value)
          end
          expect(status).to eq(201)
        end
      end

      describe 'For not admin user' do
        it 'Do not allows to create observation by not admin user' do
          post('/observations',
               params: jsonapi_params('observations', nil, { 'country-id': country.id}),
               headers: user_headers)

          expect(parsed_body).to eq(default_status_errors(401))
          expect(status).to eq(401)
        end
      end
    end

    context 'Edit observations' do
      let(:observation) { create(:observation_1, evidence: '00 Observation one') }

      describe 'For admin user' do
        it 'Returns error object when the observation cannot be updated by admin' do
          patch("/observations/#{observation.id}",
                params: jsonapi_params('observations', observation.id, { 'country-id': '' }),
                headers: admin_headers)

          expect(parsed_body).to eq(jsonapi_errors(422, 100, { 'country-id': ["can't be blank"] }))
          expect(status).to eq(422)
        end

        it 'Returns success object when the observation was seccessfully updated by admin' do
          patch("/observations/#{observation.id}",
                params: jsonapi_params('observations', observation.id, { 'is-active': false }),
                headers: admin_headers)

          expect(parsed_attributes[:'is-active']).to eq(false)
          expect(observation.reload.deactivated?).to eq(true)
          expect(status).to eq(200)
        end

        it 'Returns success object when the observation was seccessfully deactivated by admin' do
          patch("/observations/#{observation.id}",
                params: jsonapi_params('observations', observation.id, { 'is-active': false }),
                headers: admin_headers)

          expect(observation.reload.is_active).to eq(false)
          expect(status).to eq(200)
        end

        it 'Allows to translate obervation' do
          patch("/observations/#{observation.id}?locale=fr",
                params: jsonapi_params('observations', observation.id, { evidence: "FR Observation one" }),
                headers: admin_headers)

          expect(observation.reload.evidence).to eq('FR Observation one')
          I18n.locale = 'en'
          expect(observation.reload.evidence).to eq('00 Observation one')
          expect(status).to eq(200)
        end
      end

      describe 'For not admin user' do
        let(:observation_by_user) { create(:observation_1, evidence: 'Observation by ngo', user_id: ngo.id) }

        it 'Do not allows to update observation by not admin user' do
          patch("/observations/#{observation.id}",
                params: jsonapi_params('observations', observation.id, { name: 'Observation one' }),
                headers: ngo_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
        end

        it 'Do not allows to deactivated observation by user' do
          patch("/observations/#{observation_by_user.id}",
                params: jsonapi_params('observations', observation_by_user.id, { 'is-active': false }),
                headers: webuser_headers)

          expect(parsed_body).to eq(default_status_errors('401_unautorized'))
          expect(observation_by_user.reload.deactivated?).to eq(false)
          expect(status).to eq(401)
        end
      end

      describe 'User can upload attachment to observation' do
        let(:photo_data) {
          "data:image/jpeg;base64,#{Base64.encode64(File.read(File.join(Rails.root, 'spec', 'support', 'files', 'image.jpg')))}"
        }

        let(:document_data) {
          "data:application/pdf;base64,#{Base64.encode64(File.read(File.join(Rails.root, 'spec', 'support', 'files', 'doc.pdf')))}"
        }

        it 'Upload image and returns success object when the observation was seccessfully created' do
          post('/observations',
               params: jsonapi_params('observations', nil, {
                 evidence: "Observation with photo",
                 'country-id': country.id,
                 'observation-type': 'operator',
                 'publication-date': DateTime.now,
                 'photos-attributes': [{ name: 'observation photo', attachment: "#{photo_data}" }]
                }),
                headers: ngo_headers)

          expect(Observation.find_by(evidence: 'Observation with photo').photos.first.attachment.present?).to be(true)
          expect(status).to eq(201)
        end

        it 'Upload document and returns success object when the observation was seccessfully created' do
          post('/observations',
               params: jsonapi_params('observations', nil, {
                 evidence: "Observation with document",
                 'country-id': country.id,
                 'observation-type': 'operator',
                 'publication-date': DateTime.now,
                 'documents-attributes': [{ name: 'observation doc', attachment: "#{document_data}", 'document-type': 'Doumentation' }]
                }),
                headers: ngo_headers)

          expect(Observation.find_by(evidence: 'Observation with document').documents.first.attachment.present?).to be(true)
          expect(status).to eq(201)
        end
      end
    end
  end
end
