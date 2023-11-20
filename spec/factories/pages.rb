# == Schema Information
#
# Table name: pages
#
#  id                     :bigint           not null, primary key
#  slug                   :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  available_in_languages :string           is an Array
#  title                  :string
#  body                   :text
#
FactoryBot.define do
  factory :page do
    title { "Title" }
    sequence(:slug) { |n| "slug-#{n}" }
    body { "Body" }
  end
end
