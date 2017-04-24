require 'acceptance_helper'

module V1
  describe 'Law', type: :request do
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

    let!(:law) { FactoryGirl.create(:law, legal_reference: '00 Law one') }

    context 'Show laws' do
      it 'Get laws list' do
        get '/laws', headers: @headers
        expect(status).to eq(200)
      end

      it 'Get specific law' do
        get "/laws/#{law.id}", headers: @headers
        expect(status).to eq(200)
      end
    end

    context 'Pagination and sort for laws' do
      let!(:laws) {
        laws = []
        laws << FactoryGirl.create_list(:law, 4)
        laws << FactoryGirl.create(:law, legal_reference: 'ZZZ Next first one')
      }

      it 'Show list of laws for first page with per pege param' do
        get '/laws?page[number]=1&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of laws for second page with per pege param' do
        get '/laws?page[number]=2&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of laws for sort by legal_reference' do
        get '/laws?sort=legal_reference', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(6)
        expect(json[0]['attributes']['legal_reference']).to eq('00 Law one')
      end

      it 'Show list of laws for sort by legal_reference DESC' do
        get '/laws?sort=-legal_reference', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(6)
        expect(json[0]['attributes']['legal_reference']).to eq('ZZZ Next first one')
      end
    end

    context 'Create laws' do
      let!(:error) { { errors: [{ status: 422, title: "legal_reference can't be blank" }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the law cannot be created by admin' do
          post '/laws', params: {"law": { "legal_reference": "" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the law was seccessfully created by admin' do
          post '/laws', params: {"law": { "legal_reference": "Law one", "legal_penalty": "COO" }},
                        headers: @headers
          expect(status).to eq(201)
          expect(body).to   eq({ messages: [{ status: 201, title: 'Law successfully created!' }] }.to_json)
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

        it 'Do not allows to create law by not admin user' do
          post '/laws', params: {"law": { "legal_reference": "Law one", "legal_penalty": "COO" }},
                        headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Edit laws' do
      let!(:error) { { errors: [{ status: 422, title: "legal_reference can't be blank" }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the law cannot be updated by admin' do
          patch "/laws/#{law.id}", params: {"law": { "legal_reference": "" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the law was seccessfully updated by admin' do
          patch "/laws/#{law.id}", params: {"law": { "legal_reference": "Law one", "legal_penalty": "COO" }},
                                                             headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Law successfully updated!' }] }.to_json)
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

        it 'Do not allows to update law by not admin user' do
          patch "/laws/#{law.id}", params: {"law": { "legal_reference": "Law one", "legal_penalty": "COO" }},
                                                             headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Delete laws' do
      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns success object when the law was seccessfully deleted by admin' do
          delete "/laws/#{law.id}", headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Law successfully deleted!' }] }.to_json)
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

        it 'Do not allows to delete law by not admin user' do
          delete "/laws/#{law.id}", headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end
  end
end
