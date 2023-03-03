# == Schema Information
#
# Table name: categories
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  category_type :integer
#  name          :string
#

FactoryBot.define do
  factory :category do
    name { "Category name" }
    category_type { "operator" }
  end
end
