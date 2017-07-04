module V1
  class OperatorResource < JSONAPI::Resource
    attributes :name, :operator_type, :concession, :is_active, :logo, :details

    has_one :country
    has_many :fmus
    has_many   :users
    has_many :observations
  end
end
