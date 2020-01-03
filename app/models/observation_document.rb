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
  mount_base64_uploader :attachment, ObservationDocumentUploader
  acts_as_paranoid

  belongs_to :user, inverse_of: :observation_documents, touch: true
  belongs_to :observation, inverse_of: :observation_documents, touch: true

  after_destroy :remove_attachment_id_directory

  def remove_attachment_id_directory
    return if attachment.blank?

    root = Rails.env.test? ? 'spec/support' : 'public'
    FileUtils.rm_rf(File.join(root, 'uploads', model_name.singular, 'attachment', id.to_s))
  end
end
