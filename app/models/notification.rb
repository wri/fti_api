# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                   :integer          not null, primary key
#  group                :integer
#  last_displayed_at    :datetime
#  dismissed_at         :datetime
#  solved_at            :datetime
#  custom_message       :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  operator_document_id :integer          not null
#  user_id              :integer          not null
#
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :operator_document_id

  scope :displayed, -> { where.not(displayed_at: nil) }
  scope :dismissed, -> { where.not(dismissed_at: nil)}
  scope :solved, -> { where.not(solved_at: nil) }

end
