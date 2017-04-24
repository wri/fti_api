require 'acceptance_helper'

module V1
  describe 'Countries', type: :request do
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
    let!(:ngo)   { FactoryGirl.create(:ngo)   }

    let!(:country) { FactoryGirl.create(:country, name: '00 Country one') }

    context 'Show countries' do
      it 'Get countries list' do
        get '/countries', headers: @headers
        expect(status).to eq(200)
      end

      it 'Get specific country' do
        get "/countries/#{country.id}", headers: @headers
        expect(status).to eq(200)
      end
    end

    context 'Pagination and sort for countries' do
      let!(:countries) {
        countries = []
        countries << FactoryGirl.create_list(:country, 4)
        countries << FactoryGirl.create(:country, name: 'ZZZ Next first one')
      }

      it 'Show list of countries for first page with per pege param' do
        get '/countries?page[number]=1&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of countries for second page with per pege param' do
        get '/countries?page[number]=2&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of countries for sort by name' do
        get '/countries?sort=name', headers: @headers

        expect(status).to                        eq(200)
        expect(json.size).to                     eq(6)
        expect(json[0]['attributes']['name']).to eq('00 Country one')
      end

      it 'Show list of countries for sort by name DESC' do
        get '/countries?sort=-name', headers: @headers

        expect(status).to                        eq(200)
        expect(json.size).to                     eq(6)
        expect(json[0]['attributes']['name']).to eq('ZZZ Next first one')
      end
    end

    context 'Create countries' do
      let!(:error) { { errors: [{ status: 422, title: "iso can't be blank" }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the country cannot be created by admin' do
          post '/countries', params: {"country": { "name": "Test" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the country was seccessfully created by admin' do
          post '/countries', params: {"country": { "name": "Country one", "iso": "COO" }},
                             headers: @headers
          expect(status).to eq(201)
          expect(body).to   eq({ messages: [{ status: 201, title: 'Country successfully created!' }] }.to_json)
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

        it 'Do not allows to create country by not admin user' do
          post '/countries', params: {"country": { "name": "Country one", "iso": "COO" }},
                             headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Edit countries' do
      let!(:error) { { errors: [{ status: 422, title: "iso can't be blank" }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the country cannot be updated by admin' do
          patch "/countries/#{country.id}", params: {"country": { "iso": "" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the country was seccessfully updated by admin' do
          patch "/countries/#{country.id}", params: {"country": { "name": "Country one", "iso": "COO" }},
                                            headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Country successfully updated!' }] }.to_json)
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

        it 'Do not allows to update country by not admin user' do
          patch "/countries/#{country.id}", params: {"country": { "name": "Country one", "iso": "COO" }},
                                            headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Delete countries' do
      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns success object when the country was seccessfully deleted by admin' do
          delete "/countries/#{country.id}", headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Country successfully deleted!' }] }.to_json)
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

        it 'Do not allows to delete country by not admin user' do
          delete "/countries/#{country.id}", headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end
  end
end
