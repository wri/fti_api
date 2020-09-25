class AvailableValidDocumentsQuery < ValidDocumentsQuery
  def call(relation)
    super(relation).available
  end
end