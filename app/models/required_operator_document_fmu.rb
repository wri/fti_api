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

class RequiredOperatorDocumentFmu < RequiredOperatorDocument
  include ArrayForestTypeable

  has_many :operator_document_fmus, foreign_key: "required_operator_document_id", inverse_of: :required_operator_document_fmu

  validates :contract_signature, absence: true

  # empty forest_types means the document applies to all forest types
  scope :for_forest_type, ->(forest_type) {
    where(
      "COALESCE(cardinality(forest_types), 0) = 0 OR :forest_type = ANY (forest_types)",
      forest_type: Fmu.forest_types[forest_type]
    )
  }

  after_create :create_operator_document_fmus, unless: :disable_document_creation

  def create_operator_document_fmus
    fmus.find_each do |fmu|
      if fmu.operator.present? && fmu.operator.fa_id.present? # This is to prevent faulty situations when the fmu has no operator id
        OperatorDocumentFmu.where(required_operator_document_id: id,
          operator_id: fmu.operator.id,
          fmu_id: fmu.id).first_or_create do |odf|
          odf.update!(status: OperatorDocument.statuses[:doc_not_provided])
        end
      end
    end
  end

  def applies_to_forest_type?(forest_type)
    forest_types.blank? || forest_types.include?(forest_type.to_sym)
  end

  def fmus
    scope = if country_id.blank?
      Fmu.where.not(country_id: Country.active)
    else
      Fmu.where(country_id: country_id)
    end
    scope = scope.where(forest_type: forest_types) if forest_types.present?
    scope
  end
end
