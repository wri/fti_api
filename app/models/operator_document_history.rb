class OperatorDocumentHistory < ApplicationRecord
  belongs_to :operator, optional: false, touch: true
  belongs_to :required_operator_document, -> { with_archived }, required: true
  belongs_to :fmu
  belongs_to :user
  belongs_to :document_file, required: :false

  enum status: { doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4, doc_not_required: 5 }
  enum uploaded_by: { operator: 1, monitor: 2, admin: 3, other: 4 }
  enum source: { company: 1, forest_atlas: 2, other_source: 3 }

end
