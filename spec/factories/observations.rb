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

FactoryBot.define do
  factory :observation_1, class: 'Observation' do
    observation_type { 'AnnexOperator' }
    is_active { true }
    evidence { 'Operator observation' }
    publication_date { DateTime.now.to_date }
    association :country, factory: :country
    lng { 12.2222 }
    lat { 12.3333 }

    after(:create) do |observation|
      annex = FactoryBot.create(:annex_operator)

      observation.update(severity: FactoryBot.create(:severity, severable: annex),
                         annex_operator: annex,
                         user: FactoryBot.create(:admin),
                         observer: FactoryBot.create(:observer, name: "Observer #{Faker::Lorem.sentence}"),
                         operator: FactoryBot.create(:operator, name: "Operator #{Faker::Lorem.sentence}"),
                         species: [FactoryBot.create(:species)])
    end
  end

  factory :observation_2, class: 'Observation' do
    observation_type { 'AnnexGovernance' }
    is_active { true }
    evidence { 'Governance observation' }
    publication_date { (DateTime.now - 1.days).to_date }
    association :country, factory: :country
    lng { 12.2222 }
    lat { 12.3333 }

    after(:create) do |observation|
      annex = FactoryBot.create(:annex_governance)

      observation.update(severity: FactoryBot.create(:severity, severable: annex),
                         annex_governance: annex,
                         user: FactoryBot.create(:admin),
                         observer: FactoryBot.create(:observer, name: "Observer #{Faker::Lorem.sentence}"),
                         government: FactoryBot.create(:government),
                         species: [FactoryBot.create(:species, name: "Species #{Faker::Lorem.sentence}")])
    end
  end

  factory :observation, class: 'Observation' do
    observation_type { %w[operator government].sample }
    is_active { true }
    evidence { 'Operator observation' }
    publication_date { DateTime.now.to_date }
    lng { 12.2222 }
    lat { 12.3333 }

    after(:build) do |random_observation|
      country = random_observation.country
      unless random_observation.country
        # Country ISO are limited and can cause problems with uniqueness validation
        country_attributes = FactoryBot.build(:country).attributes.except('id', 'created_at', 'updated_at')
        country = Country.find_by(country_attributes) ||
                  FactoryBot.create(:country, country_attributes)
        random_observation.country = country
      end

      random_observation.subcategory ||= FactoryBot.create(:subcategory)
      random_observation.severity ||= FactoryBot.create(:severity, subcategory: random_observation.subcategory)
      random_observation.user ||= FactoryBot.create(:admin)
      random_observation.operator ||= FactoryBot.create(:operator, country: country)
      random_observation.government ||= FactoryBot.create(:government, country: country)
      random_observation.observers = [FactoryBot.create(:observer)]
      unless random_observation.species.any?
        random_observation.species ||= [FactoryBot.create(:species, name: "Species #{Faker::Lorem.sentence}")]
      end
    end
  end
end
