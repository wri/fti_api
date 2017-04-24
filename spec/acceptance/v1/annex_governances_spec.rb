require 'acceptance_helper'

module V1
  describe 'AnnexGovernance', type: :request do
    before(:each) do
      @webuser = create(:webuser)
      token    = JWT.encode({ user: @webuser.id }, ENV['AUTH_SECRET'], 'HS256')

      @headers = {
        "ACCEPT" => "application/json",
        "HTTP_OTP_API_KEY" => "Bearer #{token}"
      }
    end

    let!(:user)     { FactoryGirl.create(:user)          }
    let!(:admin)    { FactoryGirl.create(:admin)         }
    let!(:operator) { FactoryGirl.create(:operator_user) }

    let!(:annex_governance) { FactoryGirl.create(:annex_governance, governance_pillar: '00 AG one') }

    context 'Show annex_governances' do
      it 'Get annex_governances list' do
        get '/annex_governances', headers: @headers
        expect(status).to eq(200)
      end

      it 'Get specific annex_governance' do
        get "/annex_governances/#{annex_governance.id}", headers: @headers
        expect(status).to eq(200)
      end
    end

    context 'Pagination and sort for annex_governances' do
      let!(:annex_governances) {
        annex_governances = []
        annex_governances << FactoryGirl.create_list(:annex_governance, 4)
        annex_governances << FactoryGirl.create(:annex_governance, governance_pillar: 'ZZZ Next first one')
      }

      it 'Show list of annex_governances for first page with per pege param' do
        get '/annex_governances?page[number]=1&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of annex_governances for second page with per pege param' do
        get '/annex_governances?page[number]=2&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of annex_governances for sort by governance_pillar' do
        get '/annex_governances?sort=governance_pillar', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(6)
        expect(json[0]['attributes']['governance_pillar']).to eq('00 AG one')
      end

      it 'Show list of annex_governances for sort by governance_pillar DESC' do
        get '/annex_governances?sort=-governance_pillar', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(6)
        expect(json[0]['attributes']['governance_pillar']).to eq('ZZZ Next first one')
      end
    end

    context 'Create annex_governances' do
      let!(:error) { { errors: [{ status: 422, title: "governance_problem can't be blank" }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the annex_governance cannot be created by admin' do
          post '/annex_governances', params: {"annex_governance": { "governance_pillar": "Test" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the annex_governance was seccessfully created by admin' do
          post '/annex_governances', params: {"annex_governance": { "governance_pillar": "Annex Governance one", "governance_problem": "COO" }},
                             headers: @headers
          expect(status).to eq(201)
          expect(body).to   eq({ messages: [{ status: 201, title: 'Annex Governance successfully created!' }] }.to_json)
        end
      end

      describe 'For not admin user' do
        before(:each) do
          token         = JWT.encode({ user: operator.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers_user = @headers.merge("Authorization" => "Bearer #{token}")
        end

        let!(:error_unauthorized) {
          { errors: [{ status: '401', title: 'You are not authorized to access this page.' }] }
        }

        it 'Do not allows to create annex_governance by not admin user' do
          post '/annex_governances', params: {"annex_governance": { "governance_pillar": "Annex Governance one", "governance_problem": "COO" }},
                                    headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Edit annex_governances' do
      let!(:error) { { errors: [{ status: 422, title: "governance_problem can't be blank" }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the annex_governance cannot be updated by admin' do
          patch "/annex_governances/#{annex_governance.id}", params: {"annex_governance": { "governance_problem": "" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the annex_governance was seccessfully updated by admin' do
          patch "/annex_governances/#{annex_governance.id}", params: {"annex_governance": { "governance_pillar": "Annex Governance one", "governance_problem": "COO" }},
                                                             headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Annex Governance successfully updated!' }] }.to_json)
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

        it 'Do not allows to update annex_governance by not admin user' do
          patch "/annex_governances/#{annex_governance.id}", params: {"annex_governance": { "governance_pillar": "Annex Governance one", "governance_problem": "COO" }},
                                                             headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Delete annex_governances' do
      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns success object when the annex_governance was seccessfully deleted by admin' do
          delete "/annex_governances/#{annex_governance.id}", headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Annex Governance successfully deleted!' }] }.to_json)
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

        it 'Do not allows to delete annex_governance by not admin user' do
          delete "/annex_governances/#{annex_governance.id}", headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Create comments on annex_governances' do
      let!(:error) { { errors: [{ status: 422, title: "Please review Your comment body params. Params for body, commentable_type and commentable_id must be present!" }]}}

      describe 'For admin' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the annex_governance comment cannot be created by admin' do
          post "/annex_governances/#{annex_governance.id}/comments", params: {"comment": { "commentable_type": "AnnexGovernance", "commentable_id": annex_governance.id, "body": "" }},
                                                                     headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the annex_governance comment was seccessfully created by admin' do
          post "/annex_governances/#{annex_governance.id}/comments", params: {"comment": { "commentable_type": "AnnexGovernance", "commentable_id": annex_governance.id, "body": "Lorem ipsum dolor.." }},
                                                                     headers: @headers
          expect(status).to eq(201)
          expect(body).to   eq({ messages: [{ status: 201, title: 'Comment successfully created!' }] }.to_json)
        end
      end
    end

    context 'Delete comments on annex_governances' do
      let!(:comment) { Comment.create(commentable: annex_governance, user: user, body: 'Lorem ipsum..') }

      describe 'For admin' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns success object when the annex_governance comment was seccessfully created by admin' do
          delete "/annex_governances/#{annex_governance.id}/comments/#{comment.id}", headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Comment successfully deleted!' }] }.to_json)
        end
      end
    end
  end
end
