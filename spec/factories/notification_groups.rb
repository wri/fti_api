# == Schema Information
#
# Table name: notification_groups
#
#  id         :integer          not null, primary key
#  days       :integer          not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :notification_group do
    days { 10 }
  end
end
