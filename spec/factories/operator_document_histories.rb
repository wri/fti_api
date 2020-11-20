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
#

FactoryBot.define do
  factory :operator_document_history do
    user
    expire_date { Date.tomorrow }
    start_date { Date.yesterday }
    document_file { FactoryBot.build :document_file}
    operator { FactoryBot.build :operator }
    required_operator_document { FactoryBot.build :required_operator_document}

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