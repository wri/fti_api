# == Schema Information
#
# Table name: required_operator_documents
#
#  id                                  :integer          not null, primary key
#  type                                :string
#  required_operator_document_group_id :integer
#  name                                :string
#  country_id                          :integer
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  valid_period                        :integer
#  deleted_at                          :datetime
#  forest_types                        :integer          default("{}"), is an Array
#  contract_signature                  :boolean          default("false"), not null
#  required_operator_document_id       :integer          not null
#  explanation                         :text
#  deleted_at                          :datetime
#

FactoryBot.define do
  factory :required_operator_document do
    sequence(:name) { |n| "RequiredOperatorDocument#{n}" }
    valid_period { DateTime.current + 1.year }
    forest_types { [rand(0..3)] }
    explanation { 'Some explanation' }

    after(:build) do |random_required_operator_document|
      random_required_operator_document.country ||=
        FactoryBot.create(:country)
      random_required_operator_document.required_operator_document_group ||=
        FactoryBot.create(:required_operator_document_group)
    end

    factory :required_operator_document_country, class: RequiredOperatorDocumentCountry do
      type { 'RequiredOperatorDocumentCountry' }
    end

    factory :required_operator_document_fmu, class: RequiredOperatorDocumentFmu do
      type { 'RequiredOperatorDocumentFmu' }
    end
  end
end
