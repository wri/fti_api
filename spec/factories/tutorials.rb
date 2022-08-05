FactoryBot.define do
  factory :tutorial do
    sequence :position
    name { 'Name' }
    description { 'Description' }
  end
end
