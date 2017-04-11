require 'acceptance_helper'

module V1
  describe 'Governments', type: :request do
    before(:each) do
      @webuser = create(:webuser)
      token    = JWT.encode({ user: @webuser.id }, ENV['AUTH_SECRET'], 'HS256')

      @headers = {
          'ACCEPT' => 'application/json',
          'HTTP_OTP_API_KEY' => "Bearer #{token}"
      }
    end

    let!(:user)  { FactoryGirl.create(:user)  }
    let!(:admin) { FactoryGirl.create(:admin) }
    let!(:ngo)   { FactoryGirl.create(:ngo)   }

    let!(:government) { FactoryGirl.create(:government, government_entity: '00 Government one') }

    context 'Show governments' do
      it 'Get governments list' do
        get '/governments', headers: @headers
        expect(status).to eq(200)
      end

      it 'Get specific government' do
        get "/governments/#{government.id}", headers: @headers
        expect(status).to eq(200)
      end
    end


    context 'Pagination and sort for governments' do
      let!(:governments) {
        governments = []
        governments << FactoryGirl.create_list(:government, 4)
        governments << FactoryGirl.create(:government, government_entity: 'ZZZ Next first one')
      }

      it 'Show list of governments for first page with per page param' do
        get '/governments?page[number]=1&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of governments for second page with per page param' do
        get '/governments?page[number]=2&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of governments for sort by government_entity' do
        get '/governments?sort=government_entity', headers: @headers

        expect(status).to                        eq(200)
        expect(json.size).to                     eq(6)
        expect(json[0]['attributes']['government_entity']).to eq('00 Government one')
      end

      it 'Show list of governments for sort by government_entity DESC' do
        get '/governments?sort=-government_entity', headers: @headers

        expect(status).to                        eq(200)
        expect(json.size).to                     eq(6)
        expect(json[0]['attributes']['government_entity']).to eq('ZZZ Next first one')
      end
    end

    context 'Create governments' do
      let!(:error) { { errors: [{ status: 422, title: 'government_entity can\'t be blank' }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge('Authorization' => "Bearer #{token}")
        end

        it 'Returns error object when the government cannot be created by admin' do
          post '/governments', params: {'government' => { 'government_entity' => '' }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the government was successfully created by admin' do
          post '/governments', params: {'government' => { 'government_entity' => 'Government one' }},
               headers: @headers
          expect(status).to eq(201)
          expect(body).to   eq({ messages: [{ status: 201, title: 'Government successfully created!' }] }.to_json)
        end
      end

      describe 'For not admin user' do
        before(:each) do
          token         = JWT.encode({ user: user.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers_user = @headers.merge('Authorization' => "Bearer #{token}")
        end

        let!(:error_unauthorized) {
          { errors: [{ status: '401', title: 'You are not authorized to access this page.' }] }
        }

        it 'Do not allow to create governments by a non admin user' do
          post '/governments', params: {'government' => {'government_entity' => 'Government one' }},
                               headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Edit governments' do
      let!(:error) { { errors: [{ status: 422, title: 'government_entity can\'t be blank' }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge('Authorization' => "Bearer #{token}")
        end

        it 'Returns error object when the government cannot be updated by admin' do
          patch "/governments/#{government.id}", params: {'government' => { 'government_entity' => '' }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success when the government was successfully updated by admin' do
          patch "/governments/#{government.id}", params: {'government' => { 'government_entity' => 'Government one' }},
                                                 headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Government successfully updated!' }] }.to_json)
        end
      end

      describe 'For not admin user' do
        before(:each) do
          token         = JWT.encode({ user: ngo.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers_user = @headers.merge('Authorization' => "Bearer #{token}")
        end

        let!(:error_unauthorized) {
          { errors: [{ status: '401', title: 'You are not authorized to access this page.' }] }
        }

        it 'Do not allow to update government by a non admin user' do
          patch "/governments/#{government.id}", params: {'government' => { 'government_entity' => 'Government one' }},
                                               headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Delete governments' do
      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge('Authorization' => "Bearer #{token}")
        end

        it 'Returns success object when the government was successfully deleted by admin' do
          delete "/governments/#{government.id}", headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Government successfully deleted!' }] }.to_json)
        end
      end

      describe 'For not admin user' do
        before(:each) do
          token         = JWT.encode({ user: user.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers_user = @headers.merge('Authorization' => "Bearer #{token}")
        end

        let!(:error_unauthorized) {
          { errors: [{ status: '401', title: 'You are not authorized to access this page.' }] }
        }

        it 'Do not allows to delete governments by a non admin user' do
          delete "/governments/#{government.id}", headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end
  end
end
