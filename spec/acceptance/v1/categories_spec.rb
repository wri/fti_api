require 'rails_helper'

module V1
  describe 'Categories', type: :request do
    it_behaves_like "jsonapi-resources__show", Category.model_name

    it_behaves_like(
      "jsonapi-resources__create",
      Category.model_name,
      { name: 'Monitor one' },
      { name: '' },
      [422, 100, { name: ["can't be blank"] }]
    )

    it_behaves_like(
      "jsonapi-resources__edit",
      Category.model_name,
      { name: 'Monitor one' },
      { name: '' },
      [422, 100, { name: ["can't be blank"] }]
    )

    it_behaves_like "jsonapi-resources__delete", Category, Category.model_name

    context 'Pagination and sort for categories' do
      let!(:categories) {
        categories = []
        categories << FactoryBot.create(:category, name: '00 Category one')
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
  end
end
