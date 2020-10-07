# frozen_string_literal: true

class ValidDocumentsQuery
  def call(relation)
    relation.valid.ns
  end
end
