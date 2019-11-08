# frozen_string_literal: true

module V1
  class GovFileResource < JSONAPI::Resource
    caching
    attributes :attachment, :gov_document_id

    has_one :gov_document

    def custom_links(_)
      { self: nil }
    end


    private

    # Caching conditions
    def self.attribute_caching_context(context)
      {
          locale: context[:locale],
          owner: context[:current_user]
      }
    end
  end
end
