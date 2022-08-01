FactoryBot.define do
  factory :how_to do
    sequence :position
    name { 'Name' }
    description { 'Description' }
  end
end
