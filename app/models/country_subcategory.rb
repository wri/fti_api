# == Schema Information
#
# Table name: country_subcategories
#
#  id             :integer          not null, primary key
#  country_id     :integer
#  subcategory_id :integer
#  law            :text
#  penalty        :text
#  apv            :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class CountrySubcategory < ApplicationRecord
  belongs_to :country
  belongs_to :subcategory
end
