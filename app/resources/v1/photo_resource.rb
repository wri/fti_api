module V1
  class PhotoResource < JSONAPI::Resource
    caching

    attributes :name, :attachment, :user_id

    has_one :attacheable

    def custom_links(_)
      { self: nil }
    end
  end
end
