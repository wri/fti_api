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

  def generate_file_name(operator)
    return if operator.blank?

    self.filename = '' + operator.name[0...30]&.parameterize + '-' + operator.required_operator_document.name[0...100]&.parameterize + '-' + Date.today.to_s
  end
end
