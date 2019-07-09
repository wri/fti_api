FactoryGirl.define do
  factory :operator_document_annex do
    start_date { Date.yesterday }
    expire_date { Date.tomorrow }

    after(:build) do |random_operator_document_annex|
      random_operator_document_annex.operator_document ||=
        FactoryGirl.create :operator_document
      random_operator_document_annex.user ||=
        FactoryGirl.create :admin
    end
  end
end
