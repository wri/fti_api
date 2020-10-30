# frozen_string_literal: true

module OperatorDocumentable
  extend ActiveSupport::Concern

  included do
    attributes :expire_date, :start_date,
               :status, :created_at, :updated_at,
               :attachment, :operator_id, :required_operator_document_id,
               :fmu_id, :uploaded_by, :reason, :note, :response_date,
               :public, :source_info
    attribute  :source_type, delegate: :source

    has_one :country
    has_one :fmu
    has_one :operator
    has_one :required_operator_document
    has_many :operator_document_annexes, foreign_key_on: :related

    filters :type, :status, :operator_id

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

  module ClassMethods
  end
end
