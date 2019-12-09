FactoryBot.define do
  factory :operator_document do
    expire_date { Date.tomorrow }
    start_date { Date.yesterday }
    current { true }
    attachment { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'files', 'image.png')) }

    after(:build) do |random_operator_document|
      country = random_operator_document&.operator&.country ||
                random_operator_document&.required_operator_document&.country ||
                FactoryBot.create(:country)

      random_operator_document.operator ||= FactoryBot.create(:operator, country: country)
      unless random_operator_document.required_operator_document
        required_operator_document_group = FactoryBot.create(:required_operator_document_group)
        random_operator_document.required_operator_document ||= FactoryBot.create(
          :required_operator_document,
          country: country,
          required_operator_document_group: required_operator_document_group
        )
      end
      random_operator_document.user ||= FactoryBot.create(:user)
      random_operator_document.fmu ||= FactoryBot.create(:fmu, country: country)
    end

    factory :operator_document_country, class: OperatorDocumentCountry do
      type { 'OperatorDocumentCountry' }
    end

    factory :operator_document_fmu, class: OperatorDocumentFmu do
      type { 'OperatorDocumentFmu' }

      after(:build) do |random_operator_document_fmu|
        random_operator_document_fmu.required_operator_document_fmu ||=
          FactoryBot.create :required_operator_document_fmu
        random_operator_document_fmu.fmu ||= FactoryBot.create :fmu
      end
    end
  end
end
