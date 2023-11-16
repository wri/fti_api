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
require "rails_helper"

RSpec.describe RankingOperatorDocument, type: :model do
  before :all do
    @country = create(:country)
    @country_2 = create(:country)
  end

  before :each do
    @operator = create(:operator, country: @country, fa_id: "fa-id")
    @operator_2 = create(:operator, country: @country, fa_id: "fa-id2")
    @operator_3 = create(:operator, country: @country, fa_id: "fa-id3")
    @operator_4 = create(:operator, country: @country, fa_id: "fa-id4")
    @operator_inactive = create(:operator, country: @country, fa_id: "fa-id-inactive", is_active: false) # this one does not count
    @operator_5 = create(:operator, country: @country, fa_id: nil) # this one does not count
    @operator_6 = create(:operator, country: @country_2, fa_id: "fa-id5")

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

    file = create(:document_file)

    @operator.operator_document_fmus.first.update!(status: :doc_valid, document_file: file, start_date: Time.zone.today)
    @operator_6.operator_document_fmus.first.update!(status: :doc_valid, document_file: file, start_date: Time.zone.today)

    @operator_2.reload.operator_documents.each { |od| od.update!(status: :doc_valid, document_file: file, start_date: Time.zone.today) }
  end

  it "should calculate correct ranking per country" do
    expect(@operator.reload.country_doc_rank).to eq(2)
    expect(@operator_2.reload.country_doc_rank).to eq(1) # this operator has all documents valid, all: 1.0
    expect(@operator_3.reload.country_doc_rank).to eq(4)
    expect(@operator_4.reload.country_doc_rank).to eq(4)
    expect(@operator_6.reload.country_doc_rank).to eq(1)

    expect(@operator_5.reload.country_doc_rank).to be_nil
    expect(@operator_inactive.reload.country_doc_rank).to be_nil
  end

  describe "operator changes" do
    it "should remove ranking from old operator that become inactive" do
      @operator_2.update!(is_active: false)

      expect(@operator.reload.country_doc_rank).to eq(1)
      expect(@operator_2.reload.country_doc_rank).to be_nil
      expect(@operator_3.reload.country_doc_rank).to eq(3)
      expect(@operator_4.reload.country_doc_rank).to eq(3)
      expect(@operator_6.reload.country_doc_rank).to eq(1)

      expect(@operator_5.reload.country_doc_rank).to be_nil
      expect(@operator_inactive.reload.country_doc_rank).to be_nil
    end

    it "should remove ranking from operator that is not longer fa operator" do
      @operator_2.update!(fa_id: nil)

      expect(@operator.reload.country_doc_rank).to eq(1)
      expect(@operator_2.reload.country_doc_rank).to be_nil
      expect(@operator_3.reload.country_doc_rank).to eq(3)
      expect(@operator_4.reload.country_doc_rank).to eq(3)
      expect(@operator_6.reload.country_doc_rank).to eq(1)

      expect(@operator_5.reload.country_doc_rank).to be_nil
      expect(@operator_inactive.reload.country_doc_rank).to be_nil
    end
  end
end
