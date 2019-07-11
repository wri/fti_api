FactoryBot.define do
  factory :observation_document do
    sequence(:name) { |n| "ObservationDocument#{n}" }
    attachment { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'files', 'image.png')) }

    after(:build) do |random_observation_document|
      random_observation_document.user ||= FactoryBot.create(:user)
      random_observation_document.observation ||= FactoryBot.create(:observation)
    end
  end
end
