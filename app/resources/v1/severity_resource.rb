module V1
  class SeverityResource < JSONAPI::Resource
    attributes :level, :details
  end
end
