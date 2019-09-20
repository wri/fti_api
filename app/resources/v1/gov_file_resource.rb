# frozen_string_literal: true

module V1
  class GovFileResource < JSONAPI::Resource
    caching
    attributes :attachment

    has_one :gov_document
    has_one :user

    before_create :set_user_id

    def set_user_id
      if context[:current_user].present?
        @model.user_id = context[:current_user].id
        @model.uploaded_by = :operator
      end
    end


    def custom_links(_)
      { self: nil }
    end


    private

    def belongs_to_user
      context[:current_user]&.is_operator?(@model.operator_document.operator_id)
    end

    # Caching conditions
    def self.attribute_caching_context(context)
      {
          locale: context[:locale],
          owner: context[:current_user]
      }
    end
  end
end
