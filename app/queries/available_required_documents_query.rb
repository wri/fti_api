class AvailableRequiredDocumentsQuery < RequiredDocumentsQuery
  def call(relation)
    super(relation).available
  end
end