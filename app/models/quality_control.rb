# == Schema Information
#
# Table name: quality_controls
#
#  id              :bigint           not null, primary key
#  reviewable_type :string           not null
#  reviewable_id   :bigint           not null
#  reviewer_id     :bigint           not null
#  passed          :boolean          default(FALSE), not null
#  comment         :text
#  metadata        :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class QualityControl < ApplicationRecord
  belongs_to :reviewable, polymorphic: true
  belongs_to :reviewer, class_name: "User"

  validates :passed, inclusion: {in: [true, false]}
  validates :comment, presence: true, if: -> { !passed && !metadata["backfilled"] }

  before_save :set_metadata
  after_create :update_reviewable_qc_status

  private

  def set_metadata
    self.metadata = reviewable.qc_metadata(qc_passed: passed)
  end

  def update_reviewable_qc_status
    reviewable.update_qc_status!(qc_passed: passed)
  end
end
