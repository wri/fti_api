# frozen_string_literal: true

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
#  forest_types                        :integer          default([]), is an Array
#  contract_signature                  :boolean          default(FALSE), not null
#  position                            :integer
#  explanation                         :text
#  deleted_at                          :datetime
#

class RequiredOperatorDocument < ApplicationRecord
  has_paper_trail

  acts_as_paranoid
  acts_as_list scope: [:country_id, :required_operator_document_group_id, deleted_at: nil]

  attr_accessor :disable_document_creation

  include Translatable
  translates :explanation, paranoia: true, touch: true, versioning: :paper_trail
  active_admin_translates :explanation

  belongs_to :required_operator_document_group
  belongs_to :country, optional: true

  has_many :operator_documents, dependent: :destroy
  has_many :operator_document_fmus
  has_many :operator_document_countries

  has_many :operator_document_histories
  has_many :operator_document_country_histories
  has_many :operator_document_fmu_histories

  validates :valid_period, numericality: {greater_than: 0}

  validate :fixed_fields_unchanged

  after_restore :set_documents_not_provided

  scope :with_archived, -> { unscope(where: :deleted_at) }
  scope :with_generic, -> {
    join = RequiredOperatorDocument.left_joins(country: :translations)
      .arel
      .on("country_translations.country_id = countries.id and country_translations.locale = '#{I18n.locale}'")
      .join_sources

    joins(join)
  }

  def name_with_country
    "#{name} - #{country&.name || "Generic"}"
  end

  private

  def set_documents_not_provided
    operator_documents.find_each do |x|
      x.update(status: :doc_not_provided, deleted_at: nil)
    end
  end

  def fixed_fields_unchanged
    return unless persisted?

    errors.add(:contract_signature, "Cannot change the contract signature") if contract_signature_changed?
    errors.add(:forest_types, "Cannot change the forest type") if forest_types_changed?
    errors.add(:type, "Cannot change document type") if type_changed?
    errors.add(:country_id, "Cannot change the country") if country_id_changed?
  end
end
