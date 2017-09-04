module V1
  class ObservationReportResource < JSONAPI::Resource
    caching

    attributes :name, :publication_date, :created_at, :updated_at, :attachment

    has_many :observers
    has_one :user
    has_one :observations

    def custom_links(_)
      { self: nil }
    end
  end
end
