# frozen_string_literal: true

module OperatorDocumentable
  extend ActiveSupport::Concern

  included do
    include Privateable

    attributes :expire_date, :start_date,
      :status, :created_at, :updated_at,
      :attachment, :operator_id, :required_operator_document_id,
      :fmu_id, :uploaded_by, :reason, :note, :response_date,
      :public, :source_info, :admin_comment
    attribute :source_type, delegate: :source

    has_one :country
    has_one :fmu
    has_one :operator
    has_one :required_operator_document
    has_many :operator_document_annexes, foreign_key_on: :related

    filters :type, :status, :operator_id, :fmu_id, :required_operator_document_id, :country_ids, :source, :legal_categories, :forest_types

    privateable :document_visible?, [:start_date, :expire_date, :note, :reason, :response_date, :source_info, :uploaded_by, :created_at, :updated_at]

    def admin_comment
      can_see_document? ? @model.admin_comment : nil
    end

    def source_type
      return nil unless document_visible?

      @model.source
    end

    def status
      return @model.status if can_see_document?
      return @model.status if document_public? && %w[doc_not_provided doc_valid doc_expired doc_not_required].include?(@model.status)

      :doc_not_provided
    end

    def attachment
      return @model&.document_file&.attachment if document_visible?

      {url: nil}
    end

    def attachment=(attachment)
      @model.build_document_file(attachment: attachment)
    end

    def document_visible?
      can_see_document? || document_public?
    end

    def document_public?
      @model.public || @model.operator.approved
    end

    def can_see_document?
      user = @context[:current_user]
      app = @context[:app]

      return false if app == "observations-tool"
      return true if user&.user_permission&.user_role == "admin"
      return true if user&.is_operator?(@model.operator_id)

      false
    end
  end

  module ClassMethods
    def apply_includes(records, directives)
      super.includes(:document_file)
    end
  end
end
