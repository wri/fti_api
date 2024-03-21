# frozen_string_literal: true

# == Schema Information
#
# Table name: observation_documents
#
#  id                    :integer          not null, primary key
#  name                  :string
#  attachment            :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :integer
#  deleted_at            :datetime
#  document_type         :integer          default("Government Documents"), not null
#  observation_report_id :bigint
#

class ObservationDocument < ApplicationRecord
  has_paper_trail
  acts_as_paranoid
  mount_base64_uploader :attachment, ObservationDocumentUploader
  include MoveableAttachment

  enum document_type: {
    "Government Documents" => 0, "Company Documents" => 1, "Photos" => 2,
    "Testimony from local communities" => 3, "Other" => 4, "Maps" => 5
  }
  validate_enum_attributes :document_type

  validates :attachment, presence: true

  # TODO: only nils in the database, maybe that should be removed?
  belongs_to :user, inverse_of: :observation_documents, touch: true, optional: true
  belongs_to :observation_report, inverse_of: :observation_documents, touch: true, optional: true
  has_and_belongs_to_many :observations, inverse_of: :observation_documents

  skip_callback :commit, :after, :remove_attachment!
  after_destroy :move_attachment_to_private_directory
  after_restore :move_attachment_to_public_directory
  after_real_destroy :remove_attachment!
end
