# frozen_string_literal: true


# == Schema Information
#
# Table name: required_gov_documents
#
#  id                             :integer          not null, primary key
#  name                           :string           not null
#  document_type                  :integer          not null
#  valid_period                   :integer
#  deleted_at                     :datetime
#  required_gov_document_group_id :integer
#  country_id                     :integer
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#

module V1
  class RequiredGovDocumentResource < BaseResource
    include CacheableByLocale
    caching
    immutable
    attributes :name, :valid_period, :document_type,
               :required_gov_document_group_id

    has_one :country
    has_one :required_gov_document_group
    has_many :gov_documents

    filters :name, :document_type
  end
end
