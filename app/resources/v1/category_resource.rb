module V1
  class CategoryResource < JSONAPI::Resource
    attributes :name, :category_type

    has_many :subcategories
  end
end
