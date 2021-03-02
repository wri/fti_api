# frozen_string_literal: true

class ValidDocumentsQuery
  def call(relation)
    relation.valid.non_signature
  end
end
