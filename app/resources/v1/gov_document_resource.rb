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
  class GovDocumentResource < JSONAPI::Resource
    include CacheableByLocale
    include CacheableByCurrentUser
    caching
    attributes :required_gov_document_id,
               :expire_date, :start_date,
               :status, :created_at, :updated_at,
               :current, :uploaded_by, :reason,
               :link, :value, :units

    has_one :required_gov_document
    has_one :country
    has_many :gov_files

    filters :type, :status, :operator_id, :current

    before_create :set_user_id, :set_country_id, :set_current

    def set_current
      @model.current = true
    end


    def self.updatable_fields(context)
      super - [:created_at, :updated_at, :deleted_at, :status]
    end
    def self.creatable_fields(context)
      super - [:created_at, :updated_at, :deleted_at, :status]
    end

    def set_user_id
      if context[:current_user].present?
        @model.user_id = context[:current_user].id
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

    def custom_links(_)
      { self: nil }
    end

    def can_see_document?
      user = @context[:current_user]
      app = @context[:app]

      return false if app == 'observations-tool'
      return true if user&.user_permission&.user_role =='admin'
      return true if user&.is_government(@model.country_id)

      false
    end

    def hidden_document_status
      return @model.status if %w[doc_not_provided doc_valid doc_expired doc_not_required].include?(@model.status)

      :doc_not_provided
    end
  end
end
