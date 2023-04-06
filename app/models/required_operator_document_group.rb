# frozen_string_literal: true

# == Schema Information
#
# Table name: required_operator_document_groups
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  position   :integer
#  name       :string
#

class RequiredOperatorDocumentGroup < ApplicationRecord
  include Translatable
  translates :name, touch: true
  active_admin_translates :name do
    validates_presence_of :name
  end
  has_many :required_operator_documents, dependent: :destroy
  has_many :required_operator_document_countries
  has_many :required_operator_document_fmus

  scope :without_publication_authorization, -> { where.not(id: with_translations("en").where(name: "Publication Authorization")) }
end
