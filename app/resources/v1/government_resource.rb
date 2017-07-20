module V1
  class GovernmentResource < JSONAPI::Resource
    caching

    attributes :government_entity, :details

    has_one :country

    def custom_links(_)
      { self: nil }
    end
  end
end
