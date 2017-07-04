module V1
  class GovernmentResource < JSONAPI::Resource
    attributes :government_entity, :details

    has_one :country
  end
end
