# frozen_string_literal: true

module V1
  class OperatorDocumentResource < JSONAPI::Resource
    caching
    attributes :expire_date, :start_date,
               :status, :created_at, :updated_at,
               :attachment, :operator_id, :required_operator_document_id,
               :fmu_id, :current, :uploaded_by, :reason, :note, :response_date

    has_one :country
    has_one :fmu
    has_one :operator
    has_one :required_operator_document
    has_many :operator_document_annexes

    filters :type, :status, :operator_id, :current

    before_create :set_operator_id, :set_user_id

    def set_operator_id
      if context[:current_user].present? && context[:current_user].operator_id.present?
        @model.operator_id = context[:current_user].operator_id
        @model.uplodaded_by = :operator
      end
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

    def status
      user = @context[:current_user]
      app = @context[:app]
      if (app != 'observations-tool' && user.present? && user.is_operator?(@model.operator_id)) ||
          %w[doc_not_provided doc_valid doc_expired doc_not_required].include?(@model.status)
        @model.status
      else
        :doc_not_provided
      end
    end

    def self.records(options = {})
      context = options[:context]
      user = context[:current_user]
      app = context[:app]
      if app != 'observations-tool' && user.present?
        OperatorDocument.actual.from_user(user.id)
      else
        OperatorDocument.all
      end
    end


    def custom_links(_)
      { self: nil }
    end

  end
end
