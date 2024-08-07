# == Schema Information
#
# Table name: observations
#
#  id                                :integer          not null, primary key
#  severity_id                       :integer
#  observation_type                  :integer          not null
#  user_id                           :integer
#  publication_date                  :datetime
#  country_id                        :integer
#  operator_id                       :integer
#  pv                                :string
#  is_active                         :boolean          default(TRUE), not null
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  lat                               :decimal(, )
#  lng                               :decimal(, )
#  fmu_id                            :integer
#  subcategory_id                    :integer
#  validation_status                 :integer          default("Created"), not null
#  observation_report_id             :integer
#  actions_taken                     :text
#  modified_user_id                  :integer
#  law_id                            :integer
#  location_information              :string
#  is_physical_place                 :boolean          default(TRUE), not null
#  evidence_type                     :integer
#  location_accuracy                 :integer
#  evidence_on_report                :string
#  hidden                            :boolean          default(FALSE), not null
#  qc2_comment                       :text
#  monitor_comment                   :text
#  deleted_at                        :datetime
#  locale                            :string
#  qc1_comment                       :text
#  details                           :text
#  concern_opinion                   :text
#  litigation_status                 :string
#  deleted_at                        :datetime
#  details_translated_from           :string
#  concern_opinion_translated_from   :string
#  litigation_status_translated_from :string
#

FactoryBot.define do
  factory :observation, class: "Observation" do
    country
    subcategory
    observation_report
    law
    user { build(:admin) }
    severity { build(:severity, subcategory: subcategory) }
    operator { create(:operator, country: country) }
    observation_type { "operator" }
    is_active { true }
    validation_status { "Published (no comments)" }
    is_physical_place { true }
    lng { 12.2222 }
    lat { 12.3333 }

    transient do
      force_status { nil }
    end

    factory :created_observation, class: "Observation" do
      validation_status { "Created" }
    end

    after(:create) do |doc, evaluator|
      doc.update(validation_status: evaluator.force_status) if evaluator.force_status
    end
  end

  factory :gov_observation, class: "Observation" do
    severity
    country
    governments { build_list(:government, 2) }
    observers { build_list(:observer, 1) }
    user { build(:admin) }
    observation_type { "government" }
    validation_status { "Published (no comments)" }
    is_active { true }
    publication_date { DateTime.now.yesterday.to_date }
  end

  trait :with_translations do
    details { "details" }
    concern_opinion { "concern opinion" }
    litigation_status { "litigation status" }
  end
end
