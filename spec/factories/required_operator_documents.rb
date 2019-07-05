FactoryGirl.define do
  factory :required_operator_document do
    sequence(:name) { |n| "RequiredOperatorDocument#{n}" }
    valid_period { DateTime.current + 1.year }
    forest_type { rand(0..3) }

    after(:build) do |random_required_operator_document|
      random_required_operator_document.country ||=
        FactoryGirl.create(:country)
      random_required_operator_document.required_operator_document_group ||=
        FactoryGirl.create(:required_operator_document_group, country: country)
    end

    factory :required_operator_document_country do
      type { 'RequiredOperatorDocumentCountry' }
    end

    factory :required_operator_document_fmu do
      type { 'RequiredOperatorDocumentFmu' }
    end
  end
end
