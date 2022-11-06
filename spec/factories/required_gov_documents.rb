FactoryBot.define do
  factory :required_gov_document, class: RequiredGovDocument do
    required_gov_document_group
    country

    sequence(:name) { |n| "RequiredGovDocument#{n}" }
    document_type { :link }
  end
end
