# == Schema Information
#
# Table name: required_operator_documents
#
#  id                                  :integer          not null, primary key
#  type                                :string
#  required_operator_document_group_id :integer
#  name                                :string
#  country_id                          :integer
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  valid_period                        :integer
#  deleted_at                          :datetime
#

class RequiredOperatorDocument < ApplicationRecord
  acts_as_paranoid

  belongs_to :required_operator_document_group
  belongs_to :country
  has_many :operator_documents, dependent: :destroy
  has_many :operator_document_fmus
  has_many :operator_document_countries

  validates :valid_period, numericality: { greater_than: 0}
  after_destroy :invalidate_operator_documents


  def invalidate_operator_documents
    self.operator_documents.find_each{|x| x.update(status: OperatorDocument.statuses[:doc_expired])}
  end
end
