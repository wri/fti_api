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
#  government_id         :integer
#  pv                    :string
#  is_active             :boolean          default(TRUE)
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
#  is_physical_place     :boolean          default(TRUE)
#

FactoryGirl.define do
  factory :observation_1, class: 'Observation' do
    observation_type 'AnnexOperator'
    is_active         true
    evidence         'Operator observation'
    publication_date DateTime.now.to_date
    association :country, factory: :country
    lng 12.2222
    lat 12.3333

    after(:create) do |observation|
      annex = FactoryGirl.create(:annex_operator)

      observation.update(severity: FactoryGirl.create(:severity, severable: annex),
                         annex_operator: annex,
                         user: FactoryGirl.create(:admin),
                         observer: FactoryGirl.create(:observer, name: "Observer #{Faker::Lorem.sentence}"),
                         operator: FactoryGirl.create(:operator, name: "Operator #{Faker::Lorem.sentence}"),
                         species: [FactoryGirl.create(:species)])
    end
  end

  factory :observation_2, class: 'Observation' do
    observation_type 'AnnexGovernance'
    is_active         true
    evidence         'Governance observation'
    publication_date (DateTime.now - 1.days).to_date
    association :country, factory: :country
    lng 12.2222
    lat 12.3333

    after(:create) do |observation|
      annex = FactoryGirl.create(:annex_governance)

      observation.update(severity: FactoryGirl.create(:severity, severable: annex),
                         annex_governance: annex,
                         user: FactoryGirl.create(:admin),
                         observer: FactoryGirl.create(:observer, name: "Observer #{Faker::Lorem.sentence}"),
                         government: FactoryGirl.create(:government),
                         species: [FactoryGirl.create(:species, name: "Species #{Faker::Lorem.sentence}")])
    end
  end

  factory :observation, class: 'Observation' do
    observation_type { %w[operator government].sample }
    is_active         true
    evidence         'Operator observation'
    publication_date DateTime.now.to_date
    association :country, factory: :country
    lng 12.2222
    lat 12.3333

    after(:build) do |random_observation|
      random_observation.subcategory ||= FactoryGirl.create(:subcategory)
      random_observation.severity ||= FactoryGirl.create(:severity, subcategory: random_observation.subcategory)
      random_observation.user ||= FactoryGirl.create(:admin)
      random_observation.operator ||= FactoryGirl.create(:operator)
      random_observation.government ||= FactoryGirl.create(:government)
      unless random_observation.species.any?
        random_observation.species ||= [FactoryGirl.create(:species, name: "Species #{Faker::Lorem.sentence}")]
      end
    end
  end
end
