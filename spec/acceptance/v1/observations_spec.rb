require 'acceptance_helper'

module V1
  describe 'Observation', type: :request do
    before(:each) do
      @webuser = create(:webuser)
      token    = JWT.encode({ user: @webuser.id }, ENV['AUTH_SECRET'], 'HS256')

      @headers = {
        "ACCEPT" => "application/json",
        "HTTP_OTP_API_KEY" => "Bearer #{token}"
      }
    end

    let!(:user)    { FactoryGirl.create(:user)    }
    let!(:admin)   { FactoryGirl.create(:admin)   }
    let!(:ngo)     { FactoryGirl.create(:ngo)     }
    let!(:country) { FactoryGirl.create(:country) }

    let!(:observation) { FactoryGirl.create(:observation_1, evidence: '00 Observation one') }

    context 'Show observations' do
      let!(:observations) {
        observations = []
        observations << FactoryGirl.create_list(:observation_1, 4)
        observations << FactoryGirl.create(:observation, evidence: 'ZZZ Next first one', user_id: ngo.id)
        observations << FactoryGirl.create(:observation, evidence: 'AAA Next first one', user_id: ngo.id)
        observations << FactoryGirl.create(:observation, evidence: '00 Observation one', user_id: admin.id)
      }

      it 'Get observations list' do
        get '/observations', headers: @headers
        expect(status).to eq(200)
      end

      it 'Get specific observation' do
        get "/observations/#{observation.id}", headers: @headers
        expect(status).to eq(200)
      end

      describe 'Filter opbservations by user' do
        before(:each) do
          token         = JWT.encode({ user: ngo.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers_user = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Get all observations by specific user' do
          get '/observations', params: { user: admin.id }, headers: @headers
          expect(status).to eq(200)
          expect(json.size).to eq(1)
        end

        it 'Get owned observations list' do
          get '/observations', params: { user: 'current' }, headers: @headers_user
          expect(status).to eq(200)
          expect(json.size).to eq(2)
        end

        it 'Get all observations list' do
          get '/observations', params: { user: 'not' }, headers: @headers
          expect(status).to eq(200)
          expect(json.size).to eq(8)
        end
      end
    end

    context 'Pagination and sort for observations' do
      let!(:observations) {
        observations = []
        observations << FactoryGirl.create_list(:observation_2, 4)
        observations << FactoryGirl.create(:observation_1, evidence: 'ZZZ Next first one')
      }

      it 'Show list of observations for first page with per pege param' do
        get '/observations?page[number]=1&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of observations for second page with per pege param' do
        get '/observations?page[number]=2&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of observations for sort by evidence' do
        get '/observations?sort=evidence', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(6)
        expect(json[0]['attributes']['evidence']).to eq('00 Observation one')
      end

      it 'Show list of observations for sort by evidence DESC' do
        get '/observations?sort=-evidence', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(6)
        expect(json[0]['attributes']['evidence']).to eq('ZZZ Next first one')
      end

      it 'Filter by operator' do
        get '/observations?type=operator', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(2)
        expect(json[0]['attributes']['evidence']).to eq('00 Observation one')
      end

      it 'Filter by governance' do
        get '/observations?type=governance', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(4)
        expect(json[0]['attributes']['evidence']).to eq('Governance observation')
      end
    end

    context 'Create observations' do
      let!(:error) { { errors: [{ status: 422, title: "country_id can't be blank" }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the observation cannot be created by admin' do
          post '/observations', params: {"observation": { "country_id": "", observation_type: 'AnnexOperator', publication_date: DateTime.now }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the observation was seccessfully created by admin' do
          post '/observations', params: {"observation": { "country_id": country.id, observation_type: 'AnnexOperator', publication_date: DateTime.now }},
                                headers: @headers
          expect(status).to eq(201)
          expect(body).to   eq({ messages: [{ status: 201, title: 'Observation successfully created!' }] }.to_json)
        end
      end

      describe 'For not admin user' do
        before(:each) do
          token         = JWT.encode({ user: user.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers_user = @headers.merge("Authorization" => "Bearer #{token}")
        end

        let!(:error_unauthorized) {
          { errors: [{ status: '401', title: 'You are not authorized to access this page.' }] }
        }

        it 'Do not allows to create observation by not admin user' do
          post '/observations', params: {"observation": { "country_id": country.id }},
                                headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Edit observations' do
      let!(:error) { { errors: [{ status: 422, title: "country_id can't be blank" }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the observation cannot be updated by admin' do
          patch "/observations/#{observation.id}", params: {"observation": { "country_id": "" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the observation was seccessfully updated by admin' do
          patch "/observations/#{observation.id}", params: {"observation": { "is_active": false }},
                                                   headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Observation successfully updated!' }] }.to_json)
          expect(observation.reload.deactivated?).to eq(true)
        end

        it 'Returns success object when the observation was seccessfully deactivated by admin' do
          patch "/observations/#{observation.id}", params: {"observation": { "country_id": country.id }},
                                                   headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Observation successfully updated!' }] }.to_json)
          expect(observation.reload.evidence).to eq('00 Observation one')
          I18n.locale = 'en'
          expect(observation.reload.evidence).to eq('00 Observation one')
        end

        it 'Allows to translate obervation' do
          patch "/observations/#{observation.id}?locale=fr", params: {"observation": { "evidence": "FR Observation one" }},
                                                             headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Observation successfully updated!' }] }.to_json)
          expect(observation.reload.evidence).to eq('FR Observation one')
          I18n.locale = 'en'
          expect(observation.reload.evidence).to eq('00 Observation one')
        end
      end

      describe 'For not admin user' do
        before(:each) do
          token         = JWT.encode({ user: ngo.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers_user = @headers.merge("Authorization" => "Bearer #{token}")
        end

        let!(:error_unauthorized) {
          { errors: [{ status: '401', title: 'You are not authorized to access this page.' }] }
        }

        let!(:error) {
          { errors: [{ status: '401', title: 'Unauthorized' }] }
        }

        let!(:observation_by_user) { FactoryGirl.create(:observation_1, evidence: 'Observation by ngo', user_id: ngo.id) }

        it 'Do not allows to update observation by not admin user' do
          patch "/observations/#{observation.id}", params: {"observation": { "name": "Observation one" }},
                                                   headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end

        it 'Do not allows to deactivated observation by user' do
          patch "/observations/#{observation_by_user.id}", params: {"observation": { "is_active": false }},
                                                           headers: @headers
          expect(status).to eq(401)
          expect(body).to   eq(error.to_json)
          expect(observation_by_user.reload.deactivated?).to eq(false)
        end
      end

      describe 'User can upload attachment to observation' do
        let!(:photo_data) {
          "data:image/jpeg;base64,#{Base64.encode64(File.read(File.join(Rails.root, 'spec', 'support', 'files', 'image.jpg')))}"
        }

        let!(:document_data) {
          "data:application/pdf;base64,#{Base64.encode64(File.read(File.join(Rails.root, 'spec', 'support', 'files', 'doc.pdf')))}"
        }

        before(:each) do
          token         = JWT.encode({ user: ngo.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers_user = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Upload image and returns success object when the observation was seccessfully created' do
          post '/observations', params: {"observation": { "evidence": "Observation with photo", "country_id": country.id, observation_type: 'AnnexOperator', publication_date: DateTime.now, "photos_attributes": [{"name": "observation photo", "attachment": "#{photo_data}" }]}},
                                headers: @headers_user
          expect(status).to eq(201)
          expect(body).to   eq({ messages: [{ status: 201, title: 'Observation successfully created!' }] }.to_json)
          expect(Observation.find_by(evidence: 'Observation with photo').photos.first.attachment.present?).to be(true)
        end

        it 'Upload document and returns success object when the observation was seccessfully created' do
          post '/observations', params: {"observation": { "evidence": "Observation with document", "country_id": country.id, observation_type: 'AnnexOperator', publication_date: DateTime.now, "documents_attributes": [{"name": "observation doc", "attachment": "#{document_data}", document_type: "Doumentation" }]}},
                                headers: @headers_user
          expect(status).to eq(201)
          expect(body).to   eq({ messages: [{ status: 201, title: 'Observation successfully created!' }] }.to_json)
          expect(Observation.find_by(evidence: 'Observation with document').documents.first.attachment.present?).to be(true)
        end
      end
    end

    context 'Delete observations' do
      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns success object when the observation was seccessfully deleted by admin' do
          delete "/observations/#{observation.id}", headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Observation successfully deleted!' }] }.to_json)
        end
      end

      describe 'For not admin user' do
        before(:each) do
          token         = JWT.encode({ user: user.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers_user = @headers.merge("Authorization" => "Bearer #{token}")
        end

        let!(:error_unauthorized) {
          { errors: [{ status: '401', title: 'You are not authorized to access this page.' }] }
        }

        it 'Do not allows to delete observation by not admin user' do
          delete "/observations/#{observation.id}", headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end
  end
end
