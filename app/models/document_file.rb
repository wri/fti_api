# frozen_string_literal: true

# == Schema Information
#
# Table name: document_files
#
#  id         :integer          not null, primary key
#  attachment :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class DocumentFile < ApplicationRecord
  mount_base64_uploader :attachment, DocumentFileUploader

  has_one :operator_document, inverse_of: :document_file
  has_one :operator_document_history, inverse_of: :document_file

  def owner
    @owner ||= operator_document || operator_document_history
  end

  def needs_authorization_before_downloading?
    return true if owner.nil?
    return false if any_connected_document_without_authorization?

    true
  end

  private

  def any_connected_document_without_authorization?
    [operator_document, *OperatorDocumentHistory.where(document_file: self).to_a].compact.any? { !it.needs_authorization_before_downloading? }
  end
end
