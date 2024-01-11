# == Schema Information
#
# Table name: observation_documents
#
#  id             :integer          not null, primary key
#  name           :string
#  attachment     :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :integer
#  deleted_at     :datetime
#  observation_id :integer
#

FactoryBot.define do
  factory :observation_document do
    user
    sequence(:name) { |n| "ObservationDocument#{n}" }
    attachment { Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "files", "image.png")) }
  end
end
