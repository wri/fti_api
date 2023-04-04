# == Schema Information
#
# Table name: tools
#
#  id          :integer          not null, primary key
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  name        :string
#  description :text
#
FactoryBot.define do
  factory :tool do
    sequence :position
    name { "Name" }
    description { "Description" }
  end
end
