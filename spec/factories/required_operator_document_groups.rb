FactoryBot.define do
  factory :required_operator_document_group do
    sequence(:position, &:itself)
  end
end
