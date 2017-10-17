module V1
  class PartnerResource < JSONAPI::Resource
    caching
    immutable

    attributes :name, :website, :logo, :priority, :category, :description

    def custom_links(_)
      { self: nil }
    end
  end
end
