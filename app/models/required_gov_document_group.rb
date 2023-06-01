# frozen_string_literal: true

# == Schema Information
#
# Table name: required_gov_document_groups
#
#  id          :integer          not null, primary key
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#  parent_id   :bigint
#  name        :string           not null
#  description :text
#  deleted_at  :datetime
#

class RequiredGovDocumentGroup < ApplicationRecord
  include Translatable
  acts_as_paranoid

  translates :name, :description, paranoia: true, touch: true
  active_admin_translates :name do
    validates :name, presence: true
  end
  acts_as_list scope: [:parent_id]

  belongs_to :parent, class_name: "RequiredGovDocumentGroup", optional: true
  has_many :required_gov_documents, dependent: :nullify

  scope :top_level, -> { where(parent: nil) }

  def full_name
    return name if parent.nil?

    "#{parent.name} - #{name}"
  end
end
