# frozen_string_literal: true

class RequiredDocumentsQuery
  def call(relation)
    relation.required.non_signature
  end
end
