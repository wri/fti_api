module V1
  class SubcategoryResource < JSONAPI::Resource
    attributes :name, :details, :subcategory_type

    has_one :category
    has_many :severities
    has_many :country_subcategories
    has_many :observations
  end
end
