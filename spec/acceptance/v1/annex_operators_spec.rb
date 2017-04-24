require 'acceptance_helper'

module V1
  describe 'AnnexOperator', type: :request do
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

    let!(:annex_operator) { FactoryGirl.create(:annex_operator, illegality: '00 AO one') }

    context 'Show annex_operators' do
      it 'Get annex_operators list' do
        get '/annex_operators', headers: @headers
        expect(status).to eq(200)
      end

      it 'Get specific annex_operator' do
        get "/annex_operators/#{annex_operator.id}", headers: @headers
        expect(status).to eq(200)
      end
    end

    context 'Pagination and sort for annex_operators' do
      let!(:annex_operators) {
        annex_operators = []
        annex_operators << FactoryGirl.create_list(:annex_operator, 4)
        annex_operators << FactoryGirl.create(:annex_operator, illegality: 'ZZZ Next first one')
      }

      it 'Show list of annex_operators for first page with per pege param' do
        get '/annex_operators?page[number]=1&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of annex_operators for second page with per pege param' do
        get '/annex_operators?page[number]=2&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of annex_operators for sort by illegality' do
        get '/annex_operators?sort=illegality', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(6)
        expect(json[0]['attributes']['illegality']).to eq('00 AO one')
      end

      it 'Show list of annex_operators for sort by illegality DESC' do
        get '/annex_operators?sort=-illegality', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(6)
        expect(json[0]['attributes']['illegality']).to eq('ZZZ Next first one')
      end
    end

    context 'Create annex_operators' do
      let!(:error) { { errors: [{ status: 422, title: "illegality can't be blank" }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the annex_operator cannot be created by admin' do
          post '/annex_operators', params: {"annex_operator": { "illegality": "" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the annex_operator was seccessfully created by admin' do
          post '/annex_operators', params: {"annex_operator": { "illegality": "Annex Operator one" }},
                             headers: @headers
          expect(status).to eq(201)
          expect(body).to   eq({ messages: [{ status: 201, title: 'Annex Operator successfully created!' }] }.to_json)
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

        it 'Do not allows to create annex_operator by not admin user' do
          post '/annex_operators', params: {"annex_operator": { "illegality": "Annex Operator one" }},
                                    headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Edit annex_operators' do
      let!(:error) { { errors: [{ status: 422, title: "illegality can't be blank" }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the annex_operator cannot be updated by admin' do
          patch "/annex_operators/#{annex_operator.id}", params: {"annex_operator": { "illegality": "" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the annex_operator was seccessfully updated by admin' do
          patch "/annex_operators/#{annex_operator.id}", params: {"annex_operator": { "illegality": "Annex Operator one" }},
                                                             headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Annex Operator successfully updated!' }] }.to_json)
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

        it 'Do not allows to update annex_operator by not admin user' do
          patch "/annex_operators/#{annex_operator.id}", params: {"annex_operator": { "illegality": "Annex Operator one" }},
                                                             headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Delete annex_operators' do
      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns success object when the annex_operator was seccessfully deleted by admin' do
          delete "/annex_operators/#{annex_operator.id}", headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Annex Operator successfully deleted!' }] }.to_json)
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

        it 'Do not allows to delete annex_operator by not admin user' do
          delete "/annex_operators/#{annex_operator.id}", headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Create comments on annex_operators' do
      let!(:error) { { errors: [{ status: 422, title: "Please review Your comment body params. Params for body, commentable_type and commentable_id must be present!" }]}}

      describe 'For admin' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the annex_operator comment cannot be created by admin' do
          post "/annex_operators/#{annex_operator.id}/comments", params: {"comment": { "commentable_type": "AnnexOperator", "commentable_id": annex_operator.id, "body": "" }},
                                                                 headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the annex_operator comment was seccessfully created by admin' do
          post "/annex_operators/#{annex_operator.id}/comments", params: {"comment": { "commentable_type": "AnnexOperator", "commentable_id": annex_operator.id, "body": "Lorem ipsum dolor.." }},
                                                                 headers: @headers
          expect(status).to eq(201)
          expect(body).to   eq({ messages: [{ status: 201, title: 'Comment successfully created!' }] }.to_json)
        end
      end
    end

    context 'Delete comments on annex_operators' do
      let!(:comment) { Comment.create(commentable: annex_operator, user: user, body: 'Lorem ipsum..') }

      describe 'For admin' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns success object when the annex_operator comment was seccessfully created by admin' do
          delete "/annex_operators/#{annex_operator.id}/comments/#{comment.id}", headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Comment successfully deleted!' }] }.to_json)
        end
      end
    end
  end
end
