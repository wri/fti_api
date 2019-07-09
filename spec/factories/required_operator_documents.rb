FactoryGirl.define do
  factory :required_operator_document do
    sequence(:name) { |n| "RequiredOperatorDocument#{n}" }
    valid_period { DateTime.current + 1.year }
    forest_type { rand(0..3) }

    after(:build) do |random_required_operator_document|
      random_required_operator_document.country ||=
        FactoryGirl.create(:country)
      random_required_operator_document.required_operator_document_group ||=
        FactoryGirl.create(:required_operator_document_group)
    end

    factory :required_operator_document_country, class: RequiredOperatorDocumentCountry do
      type { 'RequiredOperatorDocumentCountry' }
    end

    factory :required_operator_document_fmu, class: RequiredOperatorDocumentFmu do
      type { 'RequiredOperatorDocumentFmu' }
    end
  end
end
