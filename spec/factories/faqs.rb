# == Schema Information
#
# Table name: faqs
#
#  id         :integer          not null, primary key
#  position   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  image      :string
#

FactoryBot.define do
  factory :faq do
    position { rand(0..10) }
  end
end
