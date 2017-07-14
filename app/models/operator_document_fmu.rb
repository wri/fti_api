class OperatorDocumentFmu < OperatorDocument
  belongs_to :required_operator_document_fmu
  belongs_to :fmu, optional: true
end
