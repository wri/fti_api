# == Schema Information
#
# Table name: faqs
#
#  id         :integer          not null, primary key
#  position   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  question   :string
#  answer     :text
#

FactoryBot.define do
  factory :faq do
    sequence :position
    question { 'Question' }
    answer { 'Answer' }
  end
end
