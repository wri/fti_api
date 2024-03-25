class ObservationDocumentsObservation < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  belongs_to :observation
  belongs_to :observation_document
end
