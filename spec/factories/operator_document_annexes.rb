FactoryBot.define do
  factory :operator_document_annex do
    start_date { Date.yesterday }
    expire_date { Date.tomorrow }

    after(:build) do |random_operator_document_annex|
      random_operator_document_annex.operator_document ||=
        FactoryBot.create :operator_document
      random_operator_document_annex.user ||=
        FactoryBot.create :admin
    end
  end
end
