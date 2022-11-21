# frozen_string_literal: true

module V1
  class PartnerResource < BaseResource
    caching
    immutable

    attributes :name, :website, :logo, :priority, :category, :description
  end
end
