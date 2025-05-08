# frozen_string_literal: true

module V1
  class OperatorDocumentResource < BaseResource
    include CacheableByLocale
    include CacheableByCurrentUser
    include OperatorDocumentable
    caching

    before_update :set_source, :set_public, :set_operator_id, :set_user_id, :set_status_pending

    def set_operator_id
      if context[:current_user].present? && context[:current_user].operator_id.present?
        @model.operator_id = context[:current_user].operator_id
        @model.uploaded_by = :operator
      end
    end

    def set_public
      @model.public = false
    end

    def set_source
      @model.source = OperatorDocument.sources[:company]
    end

    def set_status_pending
      @model.status = :doc_pending
    end

    def self.updatable_fields(context)
      super - [:note, :response_date, :source]
    end

    def self.creatable_fields(context)
      super - [:note, :response_date, :source]
    end

    def set_user_id
      if context[:current_user].present?
        @model.user_id = context[:current_user].id
      end
    end

    def self.records(options = {})
      context = options[:context]
      user = context[:current_user]

      records = OperatorDocument.from_active_operators
      return records if user.present? && user.admin?

      if user.present? && user.operator_ids.any?
        other_signature_documents = OperatorDocument.signature.where.not(operator_id: user.operator_ids)
        return records.where.not(id: other_signature_documents.pluck(:id))
      end
      records.where(id: OperatorDocument.non_signature) # somehow records.non_signature is not working
    end

    def self.apply_filter(records, filter, value, options)
      custom_filters = [:country_ids, :source, :legal_categories, :forest_types]
      if custom_filters.include?(filter)
        case filter
        when :country_ids
          records.by_country(value.map(&:to_i))
        when :source
          records.by_source(value.map(&:to_i))
        when :legal_categories
          records.by_required_operator_document_group(value.map(&:to_i))
        when :forest_types
          records.fmu_type.by_forest_types(value.map(&:to_i))
        else
          super(records, filter, value)
        end
      else
        super(records, filter, value)
      end
    end
  end
end
