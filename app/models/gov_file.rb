# frozen_string_literal: true

# == Schema Information
#
# Table name: gov_files
#
#  id              :integer          not null, primary key
#  attachment      :string
#  deleted_at      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  gov_document_id :integer
#

class GovFile < ApplicationRecord
  acts_as_paranoid

  belongs_to :gov_document, -> { with_archived }

  mount_base64_uploader :attachment, GovDocumentUploader
  include MoveableAttachment

  after_create :update_gov_doc_status

  after_destroy :move_attachment_to_private_directory
  after_restore :move_attachment_to_public_directory

  before_update :create_copy_and_destroy

  private

  def create_copy_and_destroy
    GovFile.create!(attachment: attachment, gov_document: gov_document)
    reload
    destroy!
  end

  def update_gov_doc_status
    return if gov_document.status == 'doc_pending'

    gov_document.update(status: GovDocument.statuses[:doc_pending])
  end
end
