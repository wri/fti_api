# == Schema Information
#
# Table name: observers
#
#  id                :integer          not null, primary key
#  observer_type     :string           not null
#  country_id        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_active         :boolean          default(TRUE)
#  logo              :string
#  address           :string
#  information_name  :string
#  information_email :string
#  information_phone :string
#  data_name         :string
#  data_email        :string
#  data_phone        :string
#  organization_type :string
#

FactoryGirl.define do
  factory :observer do
    name          "Observer #{Faker::Lorem.sentence}"
    observer_type 'External'
    logo { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'files', 'image.png')) }
  end
end
