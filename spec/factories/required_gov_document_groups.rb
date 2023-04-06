# == Schema Information
#
# Table name: required_gov_document_groups
#
#  id          :integer          not null, primary key
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#  parent_id   :bigint
#  name        :string           not null
#  description :text
#  deleted_at  :datetime
#
FactoryBot.define do
  factory :required_gov_document_group do
    sequence(:position, &:itself)
    name { "Document Group Name" }
  end
end
