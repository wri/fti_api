# == Schema Information
#
# Table name: required_operator_document_groups
#
#  id                                  :integer          not null, primary key
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  position                            :integer
#  required_operator_document_group_id :integer          not null
#  name                                :string
#

FactoryBot.define do
  factory :required_operator_document_group do
    sequence(:position, &:itself)
  end
end
