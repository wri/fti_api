# == Schema Information
#
# Table name: notifications
#
#  id                    :integer          not null, primary key
#  last_displayed_at     :datetime
#  dismissed_at          :datetime
#  solved_at             :datetime
#  operator_document_id  :integer
#  user_id               :integer
#  operator_id           :integer
#  notification_group_id :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
FactoryBot.define do
  factory :notification do
    operator_document
    user
    operator
    notification_group
  end
end
