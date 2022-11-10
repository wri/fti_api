# frozen_string_literal: true

# == Schema Information
#
# Table name: required_gov_document_groups
#
#  id                             :integer          not null, primary key
#  position                       :integer
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  deleted_at                     :datetime
#  name                           :string           not null
#  description                    :text
#  deleted_at                     :datetime
#

class RequiredGovDocumentGroup < ApplicationRecord
  include Translatable
  acts_as_paranoid

  translates :name, :description, paranoia: true, touch: true
  active_admin_translates :name do
    validates_presence_of :name
  end

  validates_presence_of :position
  has_many :required_gov_documents, dependent: :nullify
end
