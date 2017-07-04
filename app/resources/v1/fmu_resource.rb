module V1
  class FmuResource < JSONAPI::Resource
    attributes :name

    has_one :country
    has_one :operator
  end
end
