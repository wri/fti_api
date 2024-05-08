# == Schema Information
#
# Table name: observation_documents_observations
#
#  id                      :bigint           not null, primary key
#  observation_document_id :bigint           not null
#  observation_id          :bigint           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  deleted_at              :datetime
#
class ObservationDocumentsObservation < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  belongs_to :observation
  belongs_to :observation_document
end
