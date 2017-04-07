# == Schema Information
#
# Table name: photos
#
#  id               :integer          not null, primary key
#  name             :string
#  attachment       :string
#  attacheable_id   :integer
#  attacheable_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

FactoryGirl.define do
  factory :photo do
    name 'Photo'
    attachment { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'files', 'image.png')) }
    association :attacheable, factory: :observation_1
  end
end
