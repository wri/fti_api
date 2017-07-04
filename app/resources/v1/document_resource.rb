module V1
  class DocumentResource < JSONAPI::Resource
    attributes :name, :attachment, :document_type, :user_id

    has_one :attacheable
  end
end
