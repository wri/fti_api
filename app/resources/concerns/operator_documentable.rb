# frozen_string_literal: true

module OperatorDocumentable
  extend ActiveSupport::Concern

  included do
    include Privateable

    attributes :expire_date, :start_date,
      :status, :created_at, :updated_at,
      :attachment, :operator_id, :required_operator_document_id,
      :fmu_id, :uploaded_by, :reason, :response_date,
      :public, :source_info, :admin_comment
    attribute :source_type, delegate: :source

    has_one :country
    has_one :fmu
    has_one :operator
    has_one :required_operator_document
    has_many :operator_document_annexes, foreign_key_on: :related

    filters :type, :status, :operator_id, :fmu_id, :required_operator_document_id, :country_ids, :source, :legal_categories, :forest_types

    filter :contract_signature, apply: ->(records, value, _options) {
      records.joins(:required_operator_document).where(required_operator_document: {contract_signature: value})
    }

    privateable :document_visible?, [:start_date, :expire_date, :reason, :response_date, :source_info, :uploaded_by, :created_at, :updated_at]

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

      "doc_not_provided"
    end

    def attachment
      return {url: nil} if %w[doc_not_provided doc_not_required].include?(status)

      @model&.document_file&.attachment
    end

    def attachment=(attachment)
      @model.build_document_file(attachment: attachment)
      @model.annex_documents = [] # clear annexes when new document is uploaded
      # TODO: check if there is better workaround for this issue https://github.com/rails/rails/issues/49898
      # flipping activerecord flag about commit on first saved instance does not work
      # when using build_document_file probably because of autosaving - save is called twice and in after commit we lose saved_changes hash somehow
      # that's why I'm adding new_document_uploaded flag to run after_commit notifications
      @model.new_document_uploaded = true
    end

    def document_visible?
      can_see_document? || document_public?
    end

    def document_public?
      return false if @model.publication_authorization?

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
      super.includes(:document_file, :required_operator_document)
    end
  end
end
