# frozen_string_literal: true

module V1
  class OperatorDocumentAnnexResource < JSONAPI::Resource
    include CachableByLocale
    include CachableByCurrentUser
    caching
    attributes :operator_document_id, :name,
               :start_date, :expire_date, :status, :attachment,
               :uploaded_by, :created_at, :updated_at

    has_one :operator_document
    has_one :user

    filters :status, :operator_document_id

    before_create :set_user_id, :set_status, :set_public

    def name
      show_attribute('name')
    end

    def start_date
      show_attribute('start_date')
    end

    def expire_date
      show_attribute('expire_date')
    end

    def status
      show_attribute('status')
    end

    def attachment
      show_attribute('attachment')
    end

    def uploaded_by
      show_attribute('uploaded_by')
    end

    def created_at
      show_attribute('created_at')
    end

    def updated_at
      show_attribute('updated_at')
    end

    # def self.records(options = {})
    #   context = options[:context]
    #   user = context[:current_user]
    #   app = context[:app]
    #   if app != 'observations-tool' && user.present? && context[:action] != 'destroy'
    #     OperatorDocumentAnnex.from_user(user.operator_id)
    #   else
    #     OperatorDocumentAnnex.valid
    #   end
    # end

    def set_user_id
      if context[:current_user].present?
        @model.user_id = context[:current_user].id
        @model.uploaded_by = :operator
      end
    end

    def set_public
      @model.public = false
    end

    def set_status
      @model.status = OperatorDocumentAnnex.statuses[:doc_pending]
    end

    def custom_links(_)
      { self: nil }
    end

    private
    # TODO: This is a temporary solution until I don't find the problem
    # with the caching of JsonApi Resources when some records are ignored
    def show_attribute(attr)
      if @model.status == 'doc_valid' || belongs_to_user
        @model.send(attr)
      else
        nil
      end
    end

    def belongs_to_user
      context[:current_user]&.is_operator?(@model.operator_document.operator_id)
    end
  end
end
