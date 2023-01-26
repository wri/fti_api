# == Schema Information
#
# Table name: required_gov_documents
#
#  id                             :integer          not null, primary key
#  document_type                  :integer          not null
#  valid_period                   :integer
#  deleted_at                     :datetime
#  required_gov_document_group_id :integer
#  country_id                     :integer
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  position                       :integer
#  explanation                    :text
#  deleted_at                     :datetime
#  name                           :string
#
FactoryBot.define do
  factory :required_gov_document, class: RequiredGovDocument do
    required_gov_document_group
    country

    sequence(:name) { |n| "RequiredGovDocument#{n}" }
    document_type { :link }
  end
end
