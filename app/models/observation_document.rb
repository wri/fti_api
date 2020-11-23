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

  acts_as_paranoid

  belongs_to :user, inverse_of: :observation_documents, touch: true
  belongs_to :observation, inverse_of: :observation_documents, touch: true
end
