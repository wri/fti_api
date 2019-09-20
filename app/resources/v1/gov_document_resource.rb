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
    caching
    attributes :expire_date, :start_date,
               :status, :created_at, :updated_at,
               :current, :uploaded_by, :reason,
               :link, :value, :units

    has_one :required_gov_document
    has_one :country
    has_many :gov_files

    filters :type, :status, :operator_id, :current

    # before_create :set_operator_id
    before_create :set_user_id

    # def set_operator_id
    #   if context[:current_user].present? && context[:current_user].operator_id.present?
    #     @model.operator_id = context[:current_user].operator_id
    #     @model.uploaded_by = :operator
    #   end
    # end


    def self.updatable_fields(context)
      super - [:response_date]
    end
    def self.creatable_fields(context)
      super - [:response_date]
    end

    def set_user_id
      if context[:current_user].present?
        @model.user_id = context[:current_user].id
      end
    end

    # TODO: Implement permissions system here
    def status
      return @model.status if can_see_document?

      hidden_document_status
    end

    # def attachment
    #   return @model.attachment if can_see_document?
    #   return :doc_not_provided unless document_public?
    #
    #   { url: nil }
    # end


    def custom_links(_)
      { self: nil }
    end

    # Caching conditions
    def self.attribute_caching_context(context)
      {
          locale: context[:locale],
          owner: context[:current_user]
      }
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
      return :doc_not_provided
    end
  end
end
