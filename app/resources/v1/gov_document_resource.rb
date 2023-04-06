# frozen_string_literal: true

# == Schema Information
#
# Table name: gov_documents
#
#  id                       :integer          not null, primary key
#  status                   :integer          not null
#  reason                   :text
#  start_date               :date
#  expire_date              :date
#  current                  :boolean          not null
#  uploaded_by              :integer
#  link                     :string
#  value                    :string
#  units                    :string
#  deleted_at               :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  required_gov_document_id :integer
#  country_id               :integer
#  user_id                  :integer
#

module V1
  class GovDocumentResource < BaseResource
    include CacheableByLocale
    include CacheableByCurrentUser
    include Privateable
    caching
    attributes :required_gov_document_id,
      :attachment,
      :expire_date, :start_date,
      :status, :link, :value, :units

    has_one :required_gov_document
    has_one :country

    filters :type, :status, :operator_id

    before_update :set_user_id, :set_country_id, :set_status_pending

    privateable :can_see_document?, [:start_date, :expire_date, :link, :value, :units]

    def set_status_pending
      @model.status = :doc_pending
    end

    def attachment
      return @model.attachment if can_see_document?

      {url: nil}
    end

    def self.updatable_fields(context)
      [:expire_date, :start_date, :attachment, :link, :value, :units]
    end

    def set_user_id
      if context[:current_user].present?
        @model.user_id = context[:current_user].id
        @model.uploaded_by = :government
      end
    end

    def set_country_id
      @model.country_id = @model.required_gov_document&.country_id
    end

    # TODO: Implement permissions system here
    def status
      return @model.status if can_see_document?

      hidden_document_status
    end

    def can_see_document?
      user = @context[:current_user]
      app = @context[:app]

      return false if app == "observations-tool"
      return true if user&.user_permission&.user_role == "admin"
      return true if user&.is_government(@model.country_id)
      return true if @model.doc_valid?

      false
    end

    def hidden_document_status
      return @model.status if %w[doc_not_provided doc_valid doc_expired].include?(@model.status)

      :doc_not_provided
    end

    def remove
      run_callbacks :remove do
        @model.reset_to_not_provided!
        :completed
      end
    end
  end
end
