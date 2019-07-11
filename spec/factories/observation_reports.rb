FactoryBot.define do
  factory :observation_report do
    sequence(:title) { |n| "ObservationReportTitle#{n}" }
    publication_date { DateTime.current }
    attachment { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'files', 'image.png')) }

    after(:build) do |random_observation_report|
      random_observation_report.user ||= FactoryBot.create(:user)
    end
  end
end
