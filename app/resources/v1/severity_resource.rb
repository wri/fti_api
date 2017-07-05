module V1
  class SeverityResource < JSONAPI::Resource
    caching
    attributes :level, :details

    def custom_links(_)
      { self: nil }
    end
  end
end
