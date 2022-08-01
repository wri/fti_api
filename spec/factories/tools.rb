FactoryBot.define do
  factory :tool do
    sequence :position
    name { 'Name' }
    description { 'Description' }
  end
end
