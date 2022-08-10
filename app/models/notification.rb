# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                    :integer          not null, primary key
#  last_displayed_at     :datetime
#  dismissed_at          :datetime
#  solved_at             :datetime
#  operator_document_id  :integer          not null
#  user_id               :integer          not null
#  notification_group_id :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
class Notification < ApplicationRecord
  belongs_to :notification_group
  belongs_to :operator
  belongs_to :user
  belongs_to :operator_document

  # The number of months a notification is still fetchable
  # TODO: move this to an environment variable
  MONTHS_TO_FETCH = 1

  scope :newly_created, -> { where(last_displayed_at: nil, solved_at: nil) }
  scope :seen,          -> { where.not(last_displayed_at: nil).where(dismissed_at: nil, solved_at: nil) }
  scope :dismissed,     -> { where.not(dismissed_at: nil).where(solved_at: nil) }
  scope :solved,        -> { where.not(solved_at: nil) }
  scope :unsolved,      -> { where(solved_at: nil) }
  scope :visible,       -> { where(dismissed_at: nil, solved_at: nil) }
  scope :current,       -> { where("created_at > 'now'::timestamp - '#{MONTHS_TO_FETCH} month'::interval") }

  def solve!
    update(solved_at: Time.now)
  end
end
