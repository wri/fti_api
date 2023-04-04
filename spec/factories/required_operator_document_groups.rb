# == Schema Information
#
# Table name: required_operator_document_groups
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  position   :integer
#  name       :string
#

FactoryBot.define do
  factory :required_operator_document_group do
    sequence(:position, &:itself)
    name { "Document Group Name" }
  end
end
