class Subcategory < ApplicationRecord
  translates :name, :details

  belongs_to :category
  has_many :severities
  has_many :country_subcategories
end