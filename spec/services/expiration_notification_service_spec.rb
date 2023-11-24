require "rails_helper"

RSpec.describe ExpirationNotifierService do
  before :all do
    country = create(:country)
    holding = create(:holding)

    operator = create(:operator, country: country, fa_id: "fa-id")
    operator2 = create(:operator, country: country, fa_id: "fa-id2", holding: holding)

    @user1 = create(:operator_user, country: country, operator: operator)
    @user2 = create(:operator_user, country: country, operator: operator, is_active: false)
    @user3 = create(:holding_user, country: country, holding: holding)

    fmu = create(:fmu, country: country, forest_type: "vdc")
    create(:fmu_operator, fmu: fmu, operator: operator2)

    required_operator_document_group = create(:required_operator_document_group)
    required_operator_document_data = {
      country: country,
      required_operator_document_group: required_operator_document_group
    }
    create_list(:required_operator_document_country, 2, **required_operator_document_data)
    create_list(
      :required_operator_document_fmu,
      2,
      forest_types: [ForestType::TYPES_WITH_CODE[:vdc]],
      **required_operator_document_data
    )

    doc1, doc2 = operator.operator_documents.non_signature.country_type
    doc3, doc4 = operator2.operator_documents.non_signature.fmu_type.where(fmu_id: fmu.id)

    file = create(:document_file)

    doc1.update!(public: false, status: "doc_valid", document_file: file, start_date: Time.zone.yesterday, expire_date: 1.week.from_now)
    doc2.update!(public: false, status: "doc_valid", document_file: file, start_date: Time.zone.yesterday, expire_date: 1.month.from_now)
    doc3.update!(public: false, status: "doc_valid", document_file: file, start_date: 2.days.ago, expire_date: Time.zone.yesterday)
    doc4.update!(public: false, status: "doc_valid", document_file: file, start_date: Time.zone.yesterday, expire_date: 3.days.from_now)
  end

  subject { ExpirationNotifierService.new.call }

  it "sends notification to all active eligible users" do
    expect { subject }.to change { ActionMailer::Base.deliveries.count }.by(3)
      .and change { ActionMailer::Base.deliveries.flat_map(&:to).sort }.to(
        [
          @user1.email, @user1.email, # with doc1, doc2
          @user3.email # with doc4
        ].sort
      )
  end
end
