class RequiredOperatorDocument < ApplicationRecord
  belongs_to :required_operator_document_group
  belongs_to :country
end
