class RequiredDocumentsQuery
  def call(relation)
    relation.required.ns
  end
end