# frozen_string_literal: true

# == Schema Information
#
# Table name: observation_documents
#
#  id             :integer          not null, primary key
#  name           :string
#  attachment     :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :integer
#  deleted_at     :datetime
#  observation_id :integer
#

class ObservationDocument < ApplicationRecord
  has_paper_trail
  mount_base64_uploader :attachment, ObservationDocumentUploader
  include MoveableAttachment

  acts_as_paranoid

  # TODO: only nils in the database, maybe that should be removed?
  belongs_to :user, inverse_of: :observation_documents, touch: true, optional: true
  has_and_belongs_to_many :observations, inverse_of: :observation_documents

  skip_callback :commit, :after, :remove_attachment!
  after_destroy :move_attachment_to_private_directory
  after_restore :move_attachment_to_public_directory
  after_real_destroy :remove_attachment!
end
