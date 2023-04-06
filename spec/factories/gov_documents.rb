# == Schema Information
#
# Table name: gov_documents
#
#  id                       :integer          not null, primary key
#  status                   :integer          not null
#  start_date               :date
#  expire_date              :date
#  uploaded_by              :integer
#  link                     :string
#  value                    :string
#  units                    :string
#  deleted_at               :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  required_gov_document_id :integer          not null
#  country_id               :integer          not null
#  user_id                  :integer
#  attachment               :string
#
FactoryBot.define do
  factory :gov_document, class: GovDocument do
    expire_date { Date.tomorrow }
    start_date { Date.yesterday }

    transient do
      force_status { nil }
    end

    # Todo: this is needed because the gov document doesn't belong to a user. It should be fixed
    after(:build) do |doc|
      doc.user_id ||= create(:user).id
    end

    after(:create) do |doc, evaluator|
      doc.update(status: evaluator.force_status) if evaluator.force_status
    end

    trait :file do
      attachment { Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "files", "image.png")) }
    end

    trait :stats do
      value { 100 }
      units { "km2" }
    end

    trait :link do
      link { "https://example.com" }
    end

    after(:build) do |doc|
      document_type = :link
      document_type = :file if doc.attachment.present?
      document_type = :stats if doc.value.present?

      doc.required_gov_document ||= create(:required_gov_document, document_type: document_type, country: doc.country || create(:country))
    end
  end
end
