# == Schema Information
#
# Table name: observation_reports
#
#  id               :integer          not null, primary key
#  title            :string
#  publication_date :datetime
#  attachment       :string
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  deleted_at       :datetime
#

FactoryBot.define do
  factory :observation_report do
    sequence(:title) { |n| "ObservationReportTitle#{n}" }
    mission_type { "external" }
    publication_date { DateTime.current }
    attachment { Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "files", "doc.pdf")) }
    observers { build_list(:observer, 1) }

    after(:build) do |random_observation_report|
      random_observation_report.user ||= FactoryBot.create(:user)
    end
  end
end
