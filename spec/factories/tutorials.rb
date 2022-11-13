# == Schema Information
#
# Table name: tutorials
#
#  id          :integer          not null, primary key
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  name        :string
#  description :text
#
FactoryBot.define do
  factory :tutorial do
    sequence :position
    name { 'Name' }
    description { 'Description' }
  end
end
