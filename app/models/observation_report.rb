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

  acts_as_paranoid

  belongs_to :user, inverse_of: :observation_reports
  has_many :observation_report_observers
  has_many :observers, through: :observation_report_observers
  has_many :observations

  after_destroy :move_attachment_to_private_directory
  after_restore :move_attachment_to_public_directory

  scope :bigger_date, ->(date) { where('observation_reports.created_at <= ?', date + 1.day) }

  private

  def move_attachment_to_private_directory
    move_attachment(
      from: File.join('public', 'uploads', self.class.to_s.underscore, 'attachment', id.to_s),
      to: File.join('private_uploads', self.class.to_s.underscore, 'attachment')
    )
  end

  def move_attachment_to_public_directory
    move_attachment(
      from: File.join('private_uploads', self.class.to_s.underscore, 'attachment', id.to_s),
      to: File.join('public', 'uploads', self.class.to_s.underscore, 'attachment')
    )
  end

  def move_attachment(from:, to:)
    return unless attachment

    FileUtils.makedirs(to)
    FileUtils.mv(from, to)
  end
end
