# frozen_string_literal: true

module V1
  class OperatorDocumentResource < JSONAPI::Resource
    include CacheableByLocale
    include CacheableByCurrentUser
    caching
    attributes :expire_date, :start_date,
               :status, :created_at, :updated_at,
               :attachment, :operator_id, :required_operator_document_id,
               :fmu_id, :current, :uploaded_by, :reason, :note, :response_date,
               :public

    has_one :country
    has_one :fmu
    has_one :operator
    has_one :required_operator_document
    has_many :operator_document_annexes

    filters :type, :status, :operator_id, :current

    before_create :set_operator_id, :set_user_id, :set_public

    def set_operator_id
      if context[:current_user].present? && context[:current_user].operator_id.present?
        @model.operator_id = context[:current_user].operator_id
        @model.uploaded_by = :operator
      end
    end

    def set_public
      @model.public = false
    end

    def self.updatable_fields(context)
      super - [:note, :response_date]
    end
    def self.creatable_fields(context)
      super - [:note, :response_date]
    end

    def set_user_id
      if context[:current_user].present?
        @model.user_id = context[:current_user].id
      end
    end

    # TODO: Implement permissions system here
    def status
      return @model.status if can_see_document?

      # return :doc_not_provided unless document_public?

      hidden_document_status
    end

    def attachment
      return @model.attachment if can_see_document? || document_public?

      { url: nil }
    end

    def self.records(options = {})
      OperatorDocument.all

      # TODO : This code is faulty. I'm not sure if any of this is necessary.
      # It could be that when logged in, the operator could see his old
      # documents and that those should be added to the list of documents

      # context = options[:context]
      # user = context[:current_user]
      # app = context[:app]
      # if app != 'observations-tool' && user.present? && user.operator_id && context[:action] != 'destroy'
      #   OperatorDocument.actual.from_user(user.operator_id)
      # else
      #   OperatorDocument.all
      # end
    end

    def custom_links(_)
      { self: nil }
    end

    def document_public?
      @model.public || @model.operator.approved
    end

    def can_see_document?
      user = @context[:current_user]
      app = @context[:app]

      return false if app == 'observations-tool'
      return true if user&.user_permission&.user_role =='admin'
      return true if user&.is_operator?(@model.operator_id)

      false
    end

    def hidden_document_status
      return @model.status if %w[doc_not_provided doc_valid doc_expired doc_not_required].include?(@model.status)

      :doc_not_provided
    end
  end
end
