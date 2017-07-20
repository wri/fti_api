module V1
  class SeverityResource < JSONAPI::Resource
    caching
    attributes :level, :details

    filters :id, :level

    def custom_links(_)
      { self: nil }
    end
  end
end
