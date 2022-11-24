# == Schema Information
#
# Table name: gov_documents
#
#  id                       :integer          not null, primary key
#  status                   :integer          not null
#  reason                   :text
#  start_date               :date
#  expire_date              :date
#  current                  :boolean          not null
#  uploaded_by              :integer
#  link                     :string
#  value                    :string
#  units                    :string
#  deleted_at               :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  required_gov_document_id :integer
#  country_id               :integer
#  user_id                  :integer
#
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
