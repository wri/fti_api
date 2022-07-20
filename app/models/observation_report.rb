# frozen_string_literal: true

# == Schema Information
#
# Table name: observation_reports
#
#  id               :integer          not null, primary key
#  title            :string
#  publication_date :datetime
#  attachment       :string
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  deleted_at       :datetime
#

class ObservationReport < ApplicationRecord
  has_paper_trail
  mount_base64_uploader :attachment, ObservationReportUploader
  include MoveableAttachment

  acts_as_paranoid

  belongs_to :user, inverse_of: :observation_reports
  has_many :observation_report_observers, dependent: :destroy
  has_many :observers, through: :observation_report_observers
  has_many :observations, dependent: :destroy

  after_destroy :move_attachment_to_private_directory
  after_restore :move_attachment_to_public_directory

  scope :bigger_date, ->(date) { where('observation_reports.created_at <= ?', date + 1.day) }
end
