class Subcategory < ApplicationRecord
  translates :name, :details

  belongs_to :category
  has_many :severities
end