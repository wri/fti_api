# frozen_string_literal: true

module V1
  class OperatorDocumentFmuResource < JSONAPI::Resource
    caching
    attributes :expire_date, :start_date,
               :status, :created_at, :updated_at,
               :attachment, :operator_id, :required_operator_document_id,
               :fmu_id, :forest_type, :current, :reason

    has_one :country
    has_one :fmu
    has_one   :operator
    has_one :required_operator_document
    has_one :required_operator_document_fmu
    has_many :documents
    has_many :operator_document_annexes

    filters :type, :status, :operator_id, :current

    before_create :set_operator_id, :set_user_id

    def forest_type
      rod = @model.required_operator_document
      Fmu::FOREST_TYPES[rod.forest_type.to_sym][:label] if rod.forest_type
    end

    def set_operator_id
      if context[:current_user].present? && context[:current_user].operator_id.present?
        @model.operator_id = context[:current_user].operator_id
      end
    end

    def set_user_id
      if context[:current_user].present?
        @model.user_id = context[:current_user].id
      end
    end

    def status
      user = @context[:current_user]
      app = @context[:app]
      if (app != 'observations-tool' && user.present? && (user&.user_permission&.user_role =='admin' || user.is_operator?(@model.operator_id))) ||
          %w[doc_not_provided doc_valid doc_expired doc_not_required].include?(@model.status)
        @model.status
      else
        :doc_not_provided
      end
    end

    def custom_links(_)
      { self: nil }
    end

    def self.attribute_caching_context(context)
      {
          locale: context[:locale],
          owner: context[:current_user]
      }
    end
  end
end
