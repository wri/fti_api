require 'rails_helper'

module V1
  describe 'Observer', type: :request do
    it_behaves_like "jsonapi-resources__show", Observer.model_name

    it_behaves_like(
      "jsonapi-resources__create",
      Observer.model_name,
      { name: 'Monitor one', 'observer-type': 'Mandated' },
      { name: '', 'observer-type': 'Mandated' },
      [422, 100, { name: ["can't be blank"] }]
    )

    it_behaves_like(
      "jsonapi-resources__edit",
      Observer.model_name,
      { name: 'Monitor one', 'observer-type': 'Mandated' },
      { name: '', 'observer-type': 'Mandated' },
      [422, 100, { name: ["can't be blank"] }]
    )

    it_behaves_like "jsonapi-resources__delete", Observer, Observer.model_name

    describe 'Pagination and sort for observers' do
      let!(:observers) {
        observers = []
        observers << FactoryBot.create(:observer, name: '00 Monitor one')
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
  end
end
