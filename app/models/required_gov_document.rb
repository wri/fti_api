# frozen_string_literal: true

# == Schema Information
#
# Table name: required_gov_documents
#
#  id                             :integer          not null, primary key
#  document_type                  :integer          not null
#  valid_period                   :integer
#  deleted_at                     :datetime
#  required_gov_document_group_id :integer
#  country_id                     :integer
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  position                       :integer
#  explanation                    :text
#  deleted_at                     :datetime
#  name                           :string
#

class RequiredGovDocument < ApplicationRecord
  has_paper_trail
  include Translatable
  acts_as_paranoid
  acts_as_list scope: [:country_id, :required_gov_document_group_id, deleted_at: nil]

  translates :explanation, :name, paranoia: true, touch: true, versioning: :paper_trail
  active_admin_translates :explanation, :name do
    validates_presence_of :name
  end

  belongs_to :required_gov_document_group
  belongs_to :country
  has_many :gov_documents, dependent: :destroy

  enum document_type: {file: 1, link: 2, stats: 3}

  validates_inclusion_of :document_type, in: RequiredGovDocument.document_types.keys
  validates :valid_period, numericality: {greater_than: 0}, if: :valid_period?
  validate :fixed_fields_unchanged

  after_create :create_gov_document

  scope :with_archived, -> { unscope(where: :deleted_at) }

  def create_gov_document
    GovDocument
      .create_with(status: GovDocument.statuses[:doc_not_provided])
      .find_or_create_by!(required_gov_document: self)
  end

  private

  def fixed_fields_unchanged
    return unless persisted?

    errors.add(:required_gov_document_groups_id, "Cannot change the group") if required_gov_document_group_id_changed?
    errors.add(:document_type, "Cannot change the document type") if document_type_changed?
    errors.add(:country_id, "Cannot change the country") if country_id_changed?
  end
end
