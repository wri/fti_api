require 'acceptance_helper'

module V1
  describe 'Operator', type: :request do
    before(:each) do
      @webuser = create(:webuser)
      token    = JWT.encode({ user: @webuser.id }, ENV['AUTH_SECRET'], 'HS256')

      @headers = {
        "ACCEPT" => "application/json",
        "HTTP_OTP-API-KEY" => "Bearer #{token}"
      }
    end

    let!(:user)  { FactoryGirl.create(:user)  }
    let!(:admin) { FactoryGirl.create(:admin) }

    let!(:operator) { FactoryGirl.create(:operator, name: '00 Operator one') }

    context 'Show operators' do
      it 'Get operators list' do
        get '/operators', headers: @headers
        expect(status).to eq(200)
      end

      it 'Get specific operator' do
        get "/operators/#{operator.id}", headers: @headers
        expect(status).to eq(200)
      end
    end

    context 'Pagination and sort for operators' do
      let!(:operators) {
        operators = []
        operators << FactoryGirl.create_list(:operator, 4)
        operators << FactoryGirl.create(:operator, name: 'ZZZ Next first one')
      }

      it 'Show list of operators for first page with per pege param' do
        get '/operators?page[number]=1&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of operators for second page with per pege param' do
        get '/operators?page[number]=2&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of operators for sort by name' do
        get '/operators?sort=name', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(6)
        expect(json[0]['attributes']['name']).to eq('00 Operator one')
      end

      it 'Show list of operators for sort by name DESC' do
        get '/operators?sort=-name', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(6)
        expect(json[0]['attributes']['name']).to eq('ZZZ Next first one')
      end
    end

    context 'Create operators' do
      let!(:error) { { errors: [{ status: 422, title: "name can't be blank" }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the operator cannot be created by admin' do
          post '/operators', params: {"operator": { "name": "" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the operator was seccessfully created by admin' do
          post '/operators', params: {"operator": { "name": "Operator one" }},
                             headers: @headers
          expect(status).to eq(201)
          expect(body).to   eq({ messages: [{ status: 201, title: 'Operator successfully created!' }] }.to_json)
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

        it 'Do not allows to create operator by not admin user' do
          post '/operators', params: {"operator": { "name": "Operator one" }},
                             headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Edit operators' do
      let!(:error) { { errors: [{ status: 422, title: "name can't be blank" }]}}
      let!(:photo_data) {
        "data:image/jpeg;base64,#{Base64.encode64(File.read(File.join(Rails.root, 'spec', 'support', 'files', 'image.png')))}"
      }

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the operator cannot be updated by admin' do
          patch "/operators/#{operator.id}", params: {"operator": { "name": "" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the operator was seccessfully updated by admin' do
          patch "/operators/#{operator.id}", params: {"operator": { "name": "Operator one" }},
                                             headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Operator successfully updated!' }] }.to_json)
        end

        it 'Upload logo and returns success object when the operator was seccessfully updated by admin' do
          patch "/operators/#{operator.id}", params: {"operator": { "logo": photo_data }},
                                             headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Operator successfully updated!' }] }.to_json)
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

        it 'Do not allows to update operator by not admin user' do
          patch "/operators/#{operator.id}", params: {"operator": { "name": "Operator one" }},
                                             headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Delete operators' do
      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns success object when the operator was seccessfully deleted by admin' do
          delete "/operators/#{operator.id}", headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Operator successfully deleted!' }] }.to_json)
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

        it 'Do not allows to delete operator by not admin user' do
          delete "/operators/#{operator.id}", headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end
  end
end
