# == Schema Information
#
# Table name: observations
#
#  id                    :integer          not null, primary key
#  severity_id           :integer
#  observation_type      :integer          not null
#  user_id               :integer
#  publication_date      :datetime
#  country_id            :integer
#  operator_id           :integer
#  pv                    :string
#  is_active             :boolean          default(TRUE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  lat                   :decimal(, )
#  lng                   :decimal(, )
#  fmu_id                :integer
#  subcategory_id        :integer
#  validation_status     :integer          default("Created"), not null
#  observation_report_id :integer
#  actions_taken         :text
#  modified_user_id      :integer
#  law_id                :integer
#  location_information  :string
#  is_physical_place     :boolean          default(TRUE), not null
#  evidence_type         :integer
#  location_accuracy     :integer
#  evidence_on_report    :string
#  hidden                :boolean          default(FALSE), not null
#  admin_comment         :text
#  monitor_comment       :text
#  responsible_admin_id  :integer
#  deleted_at            :datetime
#  details               :text
#  concern_opinion       :text
#  litigation_status     :string
#  deleted_at            :datetime
#

FactoryBot.define do
  factory :observation_1, class: "Observation" do
    severity
    country
    species { build_list(:species, 1) }
    user { build(:admin) }
    operator { build(:operator, name: "Operator #{Faker::Lorem.sentence}") }
    observers { build_list(:observer, 1) }
    observation_type { "operator" }
    is_active { true }
    evidence_type { "Photos" }
    publication_date { DateTime.now.to_date }
    location_accuracy { "Estimated location" }
    lng { 12.2222 }
    lat { 12.3333 }

    after(:build) do |observation|
      observation.observers.each { |observer| observer.translation.name = observer.name }
    end
  end

  factory :gov_observation, class: "Observation" do
    severity
    country
    governments { build_list(:government, 2) }
    species { build_list(:species, 1, name: "Species #{Faker::Lorem.sentence}") }
    observers { build_list(:observer, 1) }
    user { build(:admin) }
    observation_type { "government" }
    validation_status { "Published (no comments)" }
    is_active { true }
    publication_date { DateTime.now.yesterday.to_date }
    lng { 12.2222 }
    lat { 12.3333 }

    after(:build) do |observation|
      observation.observers.each { |observer| observer.translation.name = observer.name }
    end
  end

  factory :observation, class: "Observation" do
    country
    subcategory
    observation_report
    law
    user { build(:admin) }
    severity { build(:severity, subcategory: subcategory) }
    operator { create(:operator, country: country) }
    observation_type { "operator" }
    observers { build_list(:observer, 1) }
    species { build_list(:species, 1, name: "Species #{Faker::Lorem.sentence}") }
    is_active { true }
    validation_status { "Published (no comments)" }
    lng { 12.2222 }
    lat { 12.3333 }

    transient do
      force_status { nil }
    end

    factory :created_observation, class: "Observation" do
      validation_status { "Created" }
    end

    after(:build) do |observation|
      observation.observers.each { |observer| observer.translation.name = observer.name }
    end

    after(:create) do |doc, evaluator|
      doc.update(validation_status: evaluator.force_status) if evaluator.force_status
    end
  end

  trait :with_translations do
    details { "details" }
    concern_opinion { "concern opinion" }
    litigation_status { "litigation status" }
  end
end
