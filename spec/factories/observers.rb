# == Schema Information
#
# Table name: observers
#
#  id                  :integer          not null, primary key
#  observer_type       :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  is_active           :boolean          default("true")
#  logo                :string
#  address             :string
#  information_name    :string
#  information_email   :string
#  information_phone   :string
#  data_name           :string
#  data_email          :string
#  data_phone          :string
#  organization_type   :string
#  public_info         :boolean          default("false")
#  responsible_user_id :integer
#  name                :string
#  organization        :string
#

FactoryBot.define do
  factory :observer do
    sequence(:name) { |n| "Observer #{n}" }
    observer_type { 'External' }
    logo { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'files', 'image.png')) }
    sequence(:information_name) { |n| "Information name #{n}" }
    sequence(:information_email) { |n| "info_email#{n}@mail.com" }
    sequence(:information_phone) { |n| ("#{n}" * 9).first(9) }
    sequence(:data_name) { |n| "Data name #{n}" }
    sequence(:data_email) { |n| "data_email#{n}@mail.com" }
    sequence(:data_phone) { |n| ("#{n}" * 9).first(9) }
  end
end
