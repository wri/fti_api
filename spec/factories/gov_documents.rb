FactoryBot.define do
  factory :gov_document, class: GovDocument do
    required_gov_document
    expire_date { Date.tomorrow }
    start_date { Date.yesterday }
    current { true }

    transient do
      force_status { nil }
    end

    # Todo: this is needed because the gov document doesn't belong to a user. It should be fixed
    after(:build) do |doc|
      doc.user_id ||= create(:user).id
    end

    after(:create) do |doc, evaluator|
      doc.update_attributes(status: evaluator.force_status) if evaluator.force_status
    end
  end
end
