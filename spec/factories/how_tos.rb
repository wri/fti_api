# == Schema Information
#
# Table name: how_tos
#
#  id          :integer          not null, primary key
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  name        :string
#  description :text
#
FactoryBot.define do
  factory :how_to do
    sequence :position
    name { 'Name' }
    description { 'Description' }
  end
end
