require 'rails_helper'

module V1
  describe 'Observer', type: :request do
    it_behaves_like "jsonapi-resources", Observer, {
      show: {},
      pagination: {},
      sort: {
        attribute: :name,
        sequence: -> (i) { "#{i} observer" }
      }
    }
  end

  context 'List observers' do
    describe 'Observers show private attributes only when they accepted it' do
      describe 'Attributes are public' do
        let(:observer) { FactoryBot.create(:observer, public_info: true) }
        it 'Shows attributes' do
          get("/observers/#{observer.id}", headers: admin_headers )
          expect(status).to eq(200)
          expect(parsed_attributes[:'information-name']).not_to be_nil
        end
      end
      describe 'Attributes are private' do
        let(:observer) { FactoryBot.create(:observer, public_info: false) }
        it "Doesn't show attributes" do
          get("/observers/#{observer.id}", headers: admin_headers )
          expect(status).to eq(200)
          expect(parsed_attributes[:'information-name']).to be_nil
        end
      end
    end
  end
end
