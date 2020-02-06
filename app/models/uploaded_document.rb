# frozen_string_literal: true

# == Schema Information
#
# Table name: uploaded_documents
#
#  id         :integer          not null, primary key
#  name       :string
#  author     :string
#  caption    :string
#  file       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class UploadedDocument < ApplicationRecord
  mount_base64_uploader :file, DocumentUploader
end
