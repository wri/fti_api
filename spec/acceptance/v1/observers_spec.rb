require 'acceptance_helper'

module V1
  describe 'Observer', type: :request do
    before(:each) do
      @webuser = create(:webuser)
      token    = JWT.encode({ user: @webuser.id }, ENV['AUTH_SECRET'], 'HS256')

      @headers = {
        "ACCEPT" => "application/json",
        "HTTP_OTP_API_KEY" => "Bearer #{token}"
      }
    end

    let!(:user)  { FactoryGirl.create(:user)  }
    let!(:admin) { FactoryGirl.create(:admin) }

    let!(:observer) { FactoryGirl.create(:observer, name: '00 Monitor one') }

    context 'Show observers' do
      it 'Get observers list' do
        get '/observers', headers: @headers
        expect(status).to eq(200)
      end

      it 'Get specific observer' do
        get "/observers/#{observer.id}", headers: @headers
        expect(status).to eq(200)
      end
    end

    context 'Pagination and sort for observers' do
      let!(:observers) {
        observers = []
        observers << FactoryGirl.create_list(:observer, 4)
        observers << FactoryGirl.create(:observer, name: 'ZZZ Next first one')
      }

      it 'Show list of observers for first page with per pege param' do
        get '/observers?page[number]=1&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of observers for second page with per pege param' do
        get '/observers?page[number]=2&page[size]=3', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(3)
      end

      it 'Show list of observers for sort by name' do
        get '/observers?sort=name', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(6)
        expect(json[0]['attributes']['name']).to eq('00 Monitor one')
      end

      it 'Show list of observers for sort by name DESC' do
        get '/observers?sort=-name', headers: @headers

        expect(status).to    eq(200)
        expect(json.size).to eq(6)
        expect(json[0]['attributes']['name']).to eq('ZZZ Next first one')
      end
    end

    context 'Create observers' do
      let!(:error) { { errors: [{ status: 422, title: "name can't be blank" }]}}

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the observer cannot be created by admin' do
          post '/observers', params: {"observer": { "name": "", "observer_type": "Mandated"  }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the observer was seccessfully created by admin' do
          post '/observers', params: {"observer": { "name": "Monitor one", "observer_type": "Mandated"  }},
                             headers: @headers
          expect(status).to eq(201)
          expect(body).to   eq({ messages: [{ status: 201, title: 'Monitor successfully created!' }] }.to_json)
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

        it 'Do not allows to create observer by not admin user' do
          post '/observers', params: {"observer": { "name": "Monitor one" }},
                             headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Edit observers' do
      let!(:error) { { errors: [{ status: 422, title: "name can't be blank" }]}}
      let!(:photo_data) {
        "data:image/jpeg;base64,#{Base64.encode64(File.read(File.join(Rails.root, 'spec', 'support', 'files', 'image.png')))}"
      }

      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns error object when the observer cannot be updated by admin' do
          patch "/observers/#{observer.id}", params: {"observer": { "name": "" }}, headers: @headers
          expect(status).to eq(422)
          expect(body).to   eq(error.to_json)
        end

        it 'Returns success object when the observer was seccessfully updated by admin' do
          patch "/observers/#{observer.id}", params: {"observer": { "name": "Monitor one" }},
                                             headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Monitor successfully updated!' }] }.to_json)
        end

        it 'Upload logo and returns success object when the observer was seccessfully updated by admin' do
          patch "/observers/#{observer.id}", params: {"observer": { "logo": photo_data }},
                                             headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Monitor successfully updated!' }] }.to_json)
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

        it 'Do not allows to update observer by not admin user' do
          patch "/observers/#{observer.id}", params: {"observer": { "name": "Monitor one" }},
                                             headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end

    context 'Delete observers' do
      describe 'For admin user' do
        before(:each) do
          token    = JWT.encode({ user: admin.id }, ENV['AUTH_SECRET'], 'HS256')
          @headers = @headers.merge("Authorization" => "Bearer #{token}")
        end

        it 'Returns success object when the observer was seccessfully deleted by admin' do
          delete "/observers/#{observer.id}", headers: @headers
          expect(status).to eq(200)
          expect(body).to   eq({ messages: [{ status: 200, title: 'Monitor successfully deleted!' }] }.to_json)
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

        it 'Do not allows to delete observer by not admin user' do
          delete "/observers/#{observer.id}", headers: @headers_user
          expect(status).to eq(401)
          expect(body).to   eq(error_unauthorized.to_json)
        end
      end
    end
  end
end
