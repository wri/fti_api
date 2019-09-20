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

  belongs_to :gov_document, ->() { with_archived }, required: true

  mount_base64_uploader :attachment, GovDocumentUploader
end
