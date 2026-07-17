FactoryBot.define do
  factory :observation_history do
    observation
    country { observation.country }
    operator { observation.operator }
    observation_type { observation.observation_type }
    validation_status { "Created" }
    observation_updated_at { Time.zone.now }
    observation_created_at { observation_updated_at }
  end
end
