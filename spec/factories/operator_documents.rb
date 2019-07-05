FactoryGirl.define do
  factory :operator_document do
    after(:build) do |random_operator_document|
      country = random_operator_document&.operator&.country ||
                random_operator_document&.required_operator_document&.country ||
                FactoryGirl.create(:country)

      random_operator_document.operator ||= FactoryGirl.create(:operator, country: country)
      unless random_operator_document.required_operator_document
        required_operator_document_group = FactoryGirl.create(:required_operator_document_group)
        random_operator_document.required_operator_document ||= FactoryGirl.create(
          :required_operator_document,
          country: country,
          required_operator_document_group: required_operator_document_group
        )
      end
      random_operator_document.user ||= FactoryGirl.create(:user)
      random_operator_document.fmu ||= FactoryGirl.create(:fmu, country: country)
    end

    factory :operator_document_country do
      type { 'OperatorDocumentCountry' }
    end

    factory :operator_document_fmu do
      type { 'OperatorDocumentFmu' }
    end
  end
end
