require 'rails_helper'

RSpec.describe GlobalScoreService do
  context '#call' do
    let!(:country_1) { FactoryBot.create(:country, is_active: true)}
    let!(:country_2) { FactoryBot.create(:country, is_active: true)}

    let!(:operator_1a) { FactoryBot.create(:operator, country_id: country_1.id, fa_id: 'a')}
    let!(:operator_1b) { FactoryBot.create(:operator, country_id: country_1.id, fa_id: 'b')}
    let!(:operator_2a) { FactoryBot.create(:operator, country_id: country_2.id, fa_id: 'c')}
    let!(:operator_12) { FactoryBot.create(:operator, country_id: country_2.id, fa_id: 'd')}

    let!(:rodg_1) { FactoryBot.create(:required_operator_document_group)}
    let!(:rodg_2) { FactoryBot.create(:required_operator_document_group)}

    let!(:rod_1a) { FactoryBot.create(:required_operator_document_country,
                                      required_operator_document_group: rodg_1, country_id: country_1.id)}
    let!(:rod_1b) { FactoryBot.create(:required_operator_document_country,
                                      required_operator_document_group: rodg_2, country_id: country_1.id)}
    let!(:rod_2a) { FactoryBot.create(:required_operator_document_country,
                                      required_operator_document_group: rodg_1, country_id: country_2.id)}
    let!(:rod_2b) { FactoryBot.create(:required_operator_document_country,
                                      required_operator_document_group: rodg_2, country_id: country_2.id)}
    let!(:global_scores) { GlobalScoreService.new.call }

    context 'Before any document changes' do
      it 'Should have 1 general global score and 2 country ones that are empty' do
        expect(GlobalScore.count).to eql(3)
        GlobalScore.find_each do |gs|
          multiply_factor = gs.country_id ? 1 : 2
          expect(gs.total_required).to eql(4 * multiply_factor)
          expect(gs.general_status).to eql({'doc_not_provided' => 4 * multiply_factor})
          expect(gs.country_status).to eql({'doc_not_provided' => 4 * multiply_factor})
          expect(gs.fmu_status).to eql({})
          expect(gs.doc_group_status.values).to eql([2*multiply_factor, 2*multiply_factor])
          expect(gs.fmu_type_status).to eql({})
        end
      end
    end

    context 'After a day' do
      before do
        travel_to Date.today + 1.day
      end

      after do
        travel_back
      end

      context 'Not changing anything' do
        let!(:new_global_scores) { GlobalScoreService.new.call }
        it 'Should have new global scores that are the same as the previous' do
          expect(GlobalScore.count).to eql(6)
          GlobalScore.where(date: Date.today).find_each do |gs|
            multiply_factor = gs.country_id ? 1 : 2
            expect(gs.total_required).to eql(4 * multiply_factor)
            expect(gs.general_status).to eql({'doc_not_provided' => 4 * multiply_factor})
            expect(gs.country_status).to eql({'doc_not_provided' => 4 * multiply_factor})
            expect(gs.fmu_status).to eql({})
            expect(gs.doc_group_status.values).to eql([2*multiply_factor, 2*multiply_factor])
            expect(gs.fmu_type_status).to eql({})
          end
        end
      end
      context 'After changing one document' do
        let!(:od) { OperatorDocument.find_by(operator: operator_1a, required_operator_document_id: rod_1a) }
        it 'The global status for today should reflect those changes' do
          od.update status: 'doc_valid'

          GlobalScoreService.new.call
          expect(GlobalScore.count).to eql(6)
          gs = GlobalScore.find_by date: Date.today, country: country_1
          expect(gs.total_required).to eql(4)
          expect(gs.general_status).to eql({'doc_not_provided' => 3, 'doc_valid' => 1})
          expect(gs.country_status).to eql({'doc_not_provided' => 3, 'doc_valid' => 1})
          expect(gs.fmu_status).to eql({})
          expect(gs.doc_group_status.values).to eql([2, 2])
          expect(gs.fmu_type_status).to eql({})
        end
      end
    end
  end
end
