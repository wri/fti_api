# == Schema Information
#
# Table name: operator_document_histories
#
#  id                            :integer          not null, primary key
#  type                          :string
#  expire_date                   :date
#  start_date                    :date
#  status                        :integer
#  uploaded_by                   :integer
#  reason                        :text
#  note                          :text
#  response_date                 :datetime
#  public                        :boolean
#  source                        :integer
#  source_info                   :string
#  fmu_id                        :integer
#  document_file_id              :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  operator_document_id          :integer
#  operator_id                   :integer
#  user_id                       :integer
#  required_operator_document_id :integer
#  deleted_at                    :datetime
#  operator_document_updated_at  :datetime         not null
#  operator_document_created_at  :datetime         not null
#

FactoryBot.define do
  factory :operator_document_history do
    user
    expire_date { Date.tomorrow }
    start_date { Date.yesterday }
    document_file { FactoryBot.build :document_file}
    operator { FactoryBot.build :operator }
    required_operator_document { FactoryBot.build :required_operator_document}

    after(:build) do |history|
      country = history&.operator&.country ||
          history&.required_operator_document&.country ||
          FactoryBot.create(:country)

      history.operator ||= FactoryBot.create(:operator, country: country)

      unless history.required_operator_document
        required_operator_document_group = FactoryBot.create(:required_operator_document_group)
        history.required_operator_document ||= FactoryBot.create(
            :required_operator_document,
            country: country,
            required_operator_document_group: required_operator_document_group
        )
      end
      unless history.operator_document
        history.operator_document ||= FactoryBot.create(:operator_document_country,
            required_operator_document: history.required_operator_document)
      end
      history.operator_document_updated_at = history.operator_document.updated_at
      history.operator_document_created_at = history.operator_document.created_at
      history.user ||= FactoryBot.create(:user)
    end

    factory :operator_document_country_history, class: OperatorDocumentCountryHistory do
      type { 'OperatorDocumentCountryHistory' }
    end

    factory :operator_document_fmu_history, class: OperatorDocumentFmuHistory do
      fmu
      required_operator_document_fmu
      type { 'OperatorDocumentFmuHistory' }
    end
  end
end
