class ValidDocumentsQuery
  def call(relation)
    relation.valid.ns
  end
end