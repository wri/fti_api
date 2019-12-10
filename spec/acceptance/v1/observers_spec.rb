require 'rails_helper'

module V1
  describe 'Observer', type: :request do
    let!(:user)  { FactoryBot.create(:user)  }
    let!(:admin) { FactoryBot.create(:admin) }
    let!(:observer) { FactoryBot.create(:observer, name: '00 Monitor one') }

    context 'Show observers' do
      it 'Get observers list' do
        get '/observers', headers: webuser_headers
        expect(status).to eq(200)
      end

      it 'Get specific observer' do
        get "/observers/#{observer.id}", headers: webuser_headers
        expect(status).to eq(200)
      end
    end

    context 'Pagination and sort for observers' do
      let!(:observers) {
        observers = []
        observers << FactoryBot.create_list(:observer, 4)
        observers << FactoryBot.create(:observer, name: 'ZZZ Next first one')
      }

      it 'Show list of observers for first page with per pege param' do
        get '/observers?page[number]=1&page[size]=3', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(3)
      end

      it 'Show list of observers for second page with per pege param' do
        get '/observers?page[number]=2&page[size]=3', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(3)
      end

      it 'Show list of observers for sort by name' do
        get '/observers?sort=name', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(6)
        expect(parsed_data[0][:attributes][:name]).to eq('00 Monitor one')
      end

      it 'Show list of observers for sort by name DESC' do
        get '/observers?sort=-name', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(6)
        expect(parsed_data[0][:attributes][:name]).to eq('ZZZ Next first one')
      end
    end

    context 'Create observers' do
      let(:error) do
        jsonapi_errors(422, 100, { name: ["can't be blank"] })
      end

      describe 'For admin user' do
        it 'Returns error object when the observer cannot be created by admin' do
          post('/observers',
               params: jsonapi_params('observers', nil, { name: '', 'observer-type' => 'Mandated' }),
               headers: admin_headers)

          expect(status).to eq(422)
          expect(parsed_body).to eq(error)
        end

        it 'Returns success object when the observer was seccessfully created by admin' do
          post('/observers',
               params: jsonapi_params('observers', nil, { name: 'Monitor one', 'observer-type' => 'Mandated' }),
               headers: admin_headers)

          expect(status).to eq(201)
          expect(parsed_data[:id]).not_to be_empty
          expect(parsed_attributes[:name]).to eq('Monitor one')
          expect(parsed_attributes[:"observer-type"]).to eq('Mandated')
          expect(parsed_attributes[:"is-active"]).to eq(false)
        end
      end

      describe 'For not admin user' do
        it 'Do not allows to create observer by not admin user' do
          post('/observers',
               params: jsonapi_params('observers', nil, { name: 'Monitor one' }),
               headers: user_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
        end
      end
    end

    context 'Edit observers' do
      let(:error) { jsonapi_errors(422, 100, { name: ["can't be blank"] }) }

      let!(:photo_data) {
        "data:image/jpeg;base64,#{Base64.encode64(File.read(File.join(Rails.root, 'spec', 'support', 'files', 'image.png')))}"
      }

      describe 'For admin user' do
        it 'Returns error object when the observer cannot be updated by admin' do
          patch("/observers/#{observer.id}",
                params: jsonapi_params('observers', observer.id, { name: '' }),
                headers: admin_headers)

          expect(status).to eq(422)
          expect(parsed_body).to eq(error)
        end

        it 'Returns success object when the observer was seccessfully updated by admin' do
          patch("/observers/#{observer.id}",
                params: jsonapi_params('observers', observer.id, { name: 'Monitor one' }),
                headers: admin_headers)

          expect(status).to eq(200)
          expect(parsed_attributes[:name]).to eq('Monitor one')
        end

        it 'Upload logo and returns success object when the observer was seccessfully updated by admin' do
          patch("/observers/#{observer.id}",
                params: jsonapi_params('observers', observer.id, { logo: photo_data }),
                headers: admin_headers)

          expect(status).to eq(200)
          expect(parsed_attributes[:logo][:url]).to end_with("spec/support/uploads/observer/logo/#{observer.id}/logo.jpeg")
        end
      end

      describe 'For not admin user' do
        it 'Do not allows to update observer by not admin user' do
          patch("/observers/#{observer.id}",
                params: jsonapi_params('observers', observer.id, { name: 'Monitor one' }),
                headers: user_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
        end
      end
    end

    context 'Delete observers' do
      describe 'For admin user' do
        it 'Returns success object when the observer was seccessfully deleted by admin' do
          delete "/observers/#{observer.id}", headers: admin_headers

          expect(status).to eq(204)
          expect(Observer.exists?(observer.id)).to be_falsey
        end
      end

      describe 'For not admin user' do
        it 'Do not allows to delete observer by not admin user' do
          delete "/observers/#{observer.id}", headers: user_headers

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
          expect(Observer.exists?(observer.id)).to be_truthy
        end
      end
    end
  end
end
