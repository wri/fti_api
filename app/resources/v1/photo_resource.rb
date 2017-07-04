module V1
  class PhotoResource < JSONAPI::Resource
    attributes :name, :attachment, :user_id

    has_one :attacheable
  end
end
