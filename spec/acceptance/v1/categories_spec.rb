require 'rails_helper'

module V1
  describe 'Categories', type: :request do
    let!(:category) { FactoryBot.create(:category, name: '00 Category one') }

    context 'Show categories' do
      it 'Get categories list' do
        get '/categories', headers: webuser_headers
        expect(status).to eq(200)
      end

      it 'Get specific category' do
        get "/categories/#{category.id}", headers: webuser_headers
        expect(status).to eq(200)
      end
    end

    context 'Pagination and sort for categories' do
      let!(:categories) {
        categories = []
        categories << FactoryBot.create_list(:category, 4)
        categories << FactoryBot.create(:category, name: 'ZZZ Next first one')
      }

      it 'Show list of categories for first page with per pege param' do
        get '/categories?page[number]=1&page[size]=3', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(3)
      end

      it 'Show list of categories for second page with per pege param' do
        get '/categories?page[number]=2&page[size]=3', headers: webuser_headers

        expect(status).to    eq(200)
        expect(parsed_data.size).to eq(3)
      end

      it 'Show list of categories for sort by name' do
        get '/categories?sort=name', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(6)
        expect(parsed_data[0][:attributes][:name]).to eq('00 Category one')
      end

      it 'Show list of categories for sort by name DESC' do
        get '/categories?sort=-name', headers: webuser_headers

        expect(status).to eq(200)
        expect(parsed_data.size).to eq(6)
        expect(parsed_data[0][:attributes][:name]).to eq('ZZZ Next first one')
      end
    end

    context 'Create categories' do
      let!(:error) { jsonapi_errors(422, 100, { name: ["can't be blank"] }) }

      describe 'For admin user' do
        it 'Returns error object when the category cannot be created by admin' do
          post('/categories',
               params: jsonapi_params('categories', nil, { name: '' }),
               headers: admin_headers)

          expect(status).to eq(422)
          expect(parsed_body).to eq(error)
        end

        it 'Returns success object when the category was seccessfully created by admin' do
          post('/categories',
               params: jsonapi_params('categories', nil, { name: 'Category one' }),
               headers: admin_headers)

          expect(status).to eq(201)
          expect(parsed_data[:id]).not_to be_empty
          expect(parsed_attributes[:name]).to eq('Category one')
        end
      end

      describe 'For not admin user' do
        it 'Do not allows to create category by not admin user' do
          post('/categories',
               params: jsonapi_params('categories', nil, { name: 'Category one' }),
               headers: user_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
        end
      end
    end

    context 'Edit categories' do
      let!(:error) { jsonapi_errors(422, 100, { name: ["can't be blank"] }) }

      describe 'For admin user' do
        it 'Returns error object when the category cannot be updated by admin' do
          patch("/categories/#{category.id}",
                params: jsonapi_params('categories', category.id, { name:  '' }),
                headers: admin_headers)

          expect(status).to eq(422)
          expect(parsed_body).to eq(error)
        end

        it 'Returns success object when the category was seccessfully updated by admin' do
          patch("/categories/#{category.id}",
                params: jsonapi_params('categories', category.id, { name: 'Category one one' }),
                headers: admin_headers)

          expect(status).to eq(200)
          expect(parsed_attributes[:name]).to eq('Category one one')
        end
      end

      describe 'For not admin user' do
        it 'Do not allows to update category by not admin user' do
          patch("/categories/#{category.id}",
                params: jsonapi_params('categories', category.id, { name: 'Category one' }),
                headers: user_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
        end
      end
    end

    context 'Delete categories' do
      describe 'For admin user' do
        it 'Returns success object when the category was seccessfully deleted by admin' do
          delete("/categories/#{category.id}", headers: admin_headers)

          expect(status).to eq(204)
          expect(Category.exists?(category.id)).to be_falsey
        end
      end

      describe 'For not admin user' do
        let!(:error_unauthorized) {
          { errors: [{ status: '401', title: 'You are not authorized to access this page.' }] }
        }

        it 'Do not allows to delete category by not admin user' do
          delete("/categories/#{category.id}", headers: user_headers)

          expect(status).to eq(401)
          expect(parsed_body).to eq(default_status_errors(401))
          expect(Category.exists?(category.id)).to be_truthy
        end
      end
    end
  end
end
