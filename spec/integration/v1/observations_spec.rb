require 'rails_helper'

module V1
  describe 'Observation', type: :request do
    it_behaves_like "jsonapi-resources", Observation, {
      show: {
        success_roles: %i[admin]
      },
      delete: {
        success_roles: %i[admin],
        failure_roles: %i[user]
      },
      # pagination: { }
    }

    let(:ngo) { create(:ngo) }
    let(:ngo_headers) { authorize_headers(create(:ngo).id) }
    let!(:country) { create(:country) }

    let!(:observation) { create(:observation_1) }

    context 'Show observations' do
      let!(:observations) {
        observations = []
        observations << create_list(:observation, 4)
        observations << create(:observation, user_id: ngo.id)
        observations << create(:observation, user_id: ngo.id)
        observations << create(:observation, user_id: admin.id)
      }

      describe 'Filter observations by user' do
        let(:ngo_headers) { authorize_headers(create(:ngo).id) }

        xit 'Get all observations by specific user' do
          get '/observations', params: { user: admin.id }, headers: webuser_headers
          expect(status).to eq(200)
          expect(parsed_data.size).to eq(1)
        end

        xit 'Get owned observations list' do
          get '/observations', params: { user: 'current' }, headers: ngo_headers
          expect(status).to eq(200)
          expect(parsed_data.size).to eq(2)
        end

        xit 'Get all observations list' do
          get '/observations', params: { user: 'not' }, headers: webuser_headers
          expect(status).to eq(200)
          expect(parsed_data.size).to eq(8)
        end
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

        it 'Returns success object when the observation was successfully created by admin' do
          params = { 'country-id': country.id, 'observation-type': 'operator', 'publication-date': DateTime.now, lat: 123.4444, lng: 12.4444 }

          post('/observations',
               params: jsonapi_params('observations', nil, params),
               headers: admin_headers)

          expect(parsed_data[:id]).not_to be_empty
          params.except(:'publication-date', :lat, :lng).each do |name, value|
            expect(parsed_attributes[name]).to eq(value)
          end
          expect(parsed_attributes[:lat]).to eq(params[:lat].to_s)
          expect(parsed_attributes[:lng]).to eq(params[:lng].to_s)
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
      let(:observation) { create(:observation_1) }

      describe 'For admin user' do
        xit 'Returns error object when the observation cannot be updated by admin' do
          patch("/observations/#{observation.id}",
                params: jsonapi_params('observations', observation.id, { 'country-id': '' }),
                headers: admin_headers)

          expect(parsed_body).to eq(jsonapi_errors(422, 100, { 'country-id': ["can't be blank"] }))
          expect(status).to eq(422)
        end

        xit 'Returns success object when the observation was successfully updated by admin' do
          patch("/observations/#{observation.id}",
                params: jsonapi_params('observations', observation.id, { 'is-active': false }),
                headers: admin_headers)

          expect(parsed_attributes[:'is-active']).to eq(false)
          expect(observation.reload.deactivated?).to eq(true)
          expect(status).to eq(200)
        end

        xit 'Returns success object when the observation was successfully deactivated by admin' do
          patch("/observations/#{observation.id}",
                params: jsonapi_params('observations', observation.id, { 'is-active': false }),
                headers: admin_headers)

          expect(observation.reload.is_active).to eq(false)
          expect(status).to eq(200)
        end

        xit 'Allows to translate observation' do
          patch("/observations/#{observation.id}?locale=fr",
                params: jsonapi_params('observations', observation.id, { details: "FR Observation one" }),
                headers: admin_headers)

          expect(observation.reload.details).to eq('FR Observation one')
          I18n.locale = 'en'
          expect(observation.reload.details).to eq('00 Observation one')
          expect(status).to eq(200)
        end
      end

      describe 'For not admin user' do
        let(:observation_by_user) { create(:observation_1, user_id: ngo.id) }

        it 'Do not allows to update observation by not admin user' do
          patch("/observations/#{observation.id}",
                params: jsonapi_params('observations', observation.id, { name: 'Observation one' }),
                headers: ngo_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
        end

        xit 'Do not allows to deactivated observation by user' do
          patch("/observations/#{observation_by_user.id}",
                params: jsonapi_params('observations', observation_by_user.id, { 'is-active': false }),
                headers: webuser_headers)

          expect(parsed_body).to eq(default_status_errors('401_unautorized'))
          expect(observation_by_user.reload.deactivated?).to eq(false)
          expect(status).to eq(401)
        end
      end

      describe 'For all users' do
        describe 'Modify status' do
          it 'Status goes from Created to Ready for QC' do
            patch("/observations/#{observation.id}?app=observations-tool",
                  params: jsonapi_params('observations', observation.id, { 'validation-status': 'Ready for QC'}),
                  headers: admin_headers)
            expect(status).to eq(200)
            expect(parsed_body[:data][:attributes][:'validation-status']).to eq('Ready for QC')
          end

          it 'Status cannot go to Needs revision' do
            patch("/observations/#{observation.id}?app=observations-tool",
                  params: jsonapi_params('observations', observation.id, { 'validation-status': 'Needs revision'}),
                  headers: admin_headers)

            expect(parsed_body[:errors].first[:title]).to eq("Invalid validation change for monitor. Can't move from 'Created'' to ''Needs revision''")
            expect(status).to eq(422)
          end
        end

        describe 'User can upload attachment to observation' do
          let(:photo_data) {
            "data:image/jpeg;base64,#{Base64.encode64(File.read(File.join(Rails.root, 'spec', 'support', 'files', 'image.jpg')))}"
          }

          let(:document_data) {
            "data:application/pdf;base64,#{Base64.encode64(File.read(File.join(Rails.root, 'spec', 'support', 'files', 'doc.pdf')))}"
          }

          xit 'Upload image and returns success object when the observation was successfully created' do
            post('/observations',
                 params: jsonapi_params('observations', nil, {
                     details: "Observation with photo",
                     'country-id': country.id,
                     'observation-type': 'operator',
                     'publication-date': DateTime.now,
                     'photos-attributes': [{ name: 'observation photo', attachment: "#{photo_data}" }]
                 }),
                 headers: ngo_headers)

            expect(Observation.find_by(details: 'Observation with photo').photos.first.attachment.present?).to be(true)
            expect(status).to eq(201)
          end

          xit 'Upload document and returns success object when the observation was successfully created' do
            post('/observations',
                 params: jsonapi_params('observations', nil, {
                     details: "Observation with document",
                     'country-id': country.id,
                     'observation-type': 'operator',
                     'publication-date': DateTime.now,
                     'documents-attributes': [{ name: 'observation doc', attachment: "#{document_data}", 'document-type': 'Doumentation' }]
                 }),
                 headers: ngo_headers)

            expect(Observation.find_by(details: 'Observation with document').documents.first.attachment.present?).to be(true)
            expect(status).to eq(201)
          end
        end
      end


    end
  end
end
