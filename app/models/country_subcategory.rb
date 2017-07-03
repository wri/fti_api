class CountrySubcategory < ApplicationRecord
  belongs_to :country
  belongs_to :subcategory
end