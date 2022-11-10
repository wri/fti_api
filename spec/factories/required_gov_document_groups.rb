FactoryBot.define do
  factory :required_gov_document_group do
    sequence(:position, &:itself)
    name { 'Document Group Name' }
  end
end
