# == Schema Information
#
# Table name: operator_documents
#
#  id                            :integer          not null, primary key
#  type                          :string
#  expire_date                   :date
#  start_date                    :date
#  fmu_id                        :integer
#  required_operator_document_id :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  status                        :integer
#  operator_id                   :integer
#  deleted_at                    :datetime
#  uploaded_by                   :integer
#  user_id                       :integer
#  reason                        :text
#  note                          :text
#  response_date                 :datetime
#  public                        :boolean          default(TRUE), not null
#  source                        :integer          default("company")
#  source_info                   :string
#  document_file_id              :integer
#

FactoryBot.define do
  factory :operator_document, class: OperatorDocumentCountry, aliases: [:operator_document_country] do
    user
    expire_date { Date.tomorrow }
    start_date { Date.yesterday }
    type { 'OperatorDocumentCountry' } # This can be overwritten by the children.
    document_file { build :document_file }

    transient do
      force_status { nil }
    end

    after(:build) do |doc|
      country = doc&.operator&.country ||
        doc&.required_operator_document&.country ||
        FactoryBot.create(:country)

      doc.operator ||= FactoryBot.create(:operator, country: country)

      unless doc.required_operator_document
        doc.required_operator_document ||= FactoryBot.create(
          :required_operator_document_country,
          country: country,
          required_operator_document_group: FactoryBot.create(:required_operator_document_group),
          disable_document_creation: true
        )
      end
      doc.user ||= FactoryBot.create(:user)
    end

    factory :operator_document_fmu, class: OperatorDocumentFmu do
      fmu
      required_operator_document_fmu
      type { 'OperatorDocumentFmu' }

      after(:build) do |doc|
        doc.fmu ||= FactoryBot.create(:fmu, country: country)
      end
    end

    after(:create) do |doc, evaluator|
      doc.update_attributes(status: evaluator.force_status) if evaluator.force_status
    end
  end
end
