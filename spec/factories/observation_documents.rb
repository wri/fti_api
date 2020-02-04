FactoryBot.define do
  factory :observation_document do
    user
    observation
    sequence(:name) { |n| "ObservationDocument#{n}" }
    attachment { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'files', 'image.png')) }
  end
end
