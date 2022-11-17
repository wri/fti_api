module V1
  class BaseResource < JSONAPI::Resource
    abstract

    def custom_links(_)
      { self: nil }
    end
  end
end
