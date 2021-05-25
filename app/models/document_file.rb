# frozen_string_literal: true

# == Schema Information
#
# Table name: document_files
#
#  id         :integer          not null, primary key
#  attachment :string
#  file_name  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class DocumentFile < ApplicationRecord
  mount_base64_uploader :attachment, DocumentFileUploader

  has_one :operator_document, inverse_of: :document_file
end
