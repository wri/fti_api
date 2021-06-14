# == Schema Information
#
# Table name: ranking_operator_documents
#
#  id          :integer          not null, primary key
#  date        :date             not null
#  current     :boolean          default("true"), not null
#  position    :integer          not null
#  operator_id :integer
#  country_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe RankingOperatorDocument, type: :model do
  before do
    @country = create(:country)
    @country_2 = create(:country)
    @operator = create(:operator, country: @country, fa_id: 'fa-id')
    @operator_2 = create(:operator, country: @country, fa_id: 'fa-id2')
    @operator_3 = create(:operator, country: @country, fa_id: 'fa-id3')
    @operator_4 = create(:operator, country: @country, fa_id: 'fa-id4')
    @operator_inactive = create(:operator, country: @country, fa_id: 'fa-id-inactive', is_active: false) # this one does not count
    @operator_5 = create(:operator, country: @country, fa_id: nil) # this one does not count
    @operator_6 = create(:operator, country: @country_2, fa_id: 'fa-id5')

    @dg = create(:required_operator_document_group)

    fmu = create(:fmu, country: @country, forest_type: 1)
    fmu2 = create(:fmu, country: @country_2, forest_type: 1)
    fmu3 = create(:fmu, country: @country, forest_type: 1)

    create(:required_operator_document_country, country: @country, required_operator_document_group: @dg)
    create(:required_operator_document_country, country: @country_2, required_operator_document_group: @dg)
    create(:required_operator_document_fmu, country: @country, required_operator_document_group: @dg, forest_types: [1])
    create(:required_operator_document_fmu, country: @country_2, required_operator_document_group: @dg, forest_types: [1])

    create(:fmu_operator, fmu: fmu, operator: @operator)
    create(:fmu_operator, fmu: fmu2, operator: @operator_6)
    create(:fmu_operator, fmu: fmu3, operator: @operator_2)

    @operator.operator_document_fmus.first.update!(status: :doc_valid)
    @operator_6.operator_document_fmus.first.update!(status: :doc_valid)

    @operator_2.reload.operator_documents.each { |od| od.update(status: :doc_valid) }
  end

  it 'should calculate correct ranking per country' do
    op_rank = RankingOperatorDocument.for_operator(@operator)
    op2_rank = RankingOperatorDocument.for_operator(@operator_2)
    op3_rank = RankingOperatorDocument.for_operator(@operator_3)
    op4_rank = RankingOperatorDocument.for_operator(@operator_4)
    op5_rank = RankingOperatorDocument.for_operator(@operator_5)
    op6_rank = RankingOperatorDocument.for_operator(@operator_6)
    op_inactive_rank = RankingOperatorDocument.for_operator(@operator_inactive)

    expect(op_rank.position).to eq(2)
    expect(op2_rank.position).to eq(1) # this operator has all documents valid, all: 1.0
    expect(op3_rank.position).to eq(4)
    expect(op4_rank.position).to eq(4)
    expect(op6_rank.position).to eq(1)

    expect(op5_rank).to be_nil
    expect(op_inactive_rank).to be_nil
  end
end
