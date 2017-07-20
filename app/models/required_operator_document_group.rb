# == Schema Information
#
# Table name: required_operator_document_groups
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class RequiredOperatorDocumentGroup < ApplicationRecord
  translates :name, :details
  has_many :required_operator_documents, dependent: :destroy
  has_many :required_operator_document_countries
  has_many :required_operator_document_fmus
end
