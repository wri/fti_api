module V1
  class OperatorResource < JSONAPI::Resource
    caching
    attributes :name, :operator_type, :concession, :is_active, :logo, :details

    has_one :country
    has_many :fmus
    has_many   :users
    has_many :observations

    filter :country

    def custom_links(_)
      { self: nil }
    end
  end
end
