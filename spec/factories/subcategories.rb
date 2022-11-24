# == Schema Information
#
# Table name: subcategories
#
#  id                :integer          not null, primary key
#  category_id       :integer
#  subcategory_type  :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  location_required :boolean          default(TRUE)
#  name              :text
#  details           :text
#

FactoryBot.define do
  factory :subcategory, class: 'Subcategory' do
    sequence(:name) { |n| "Subcategory#{n}" }
    subcategory_type { rand(0..1) }

    after(:build) do |random_subcategory|
      random_subcategory.category ||= FactoryBot.create(:category)
    end
  end
end
