require 'rails_helper'

module V1
  describe 'Subcategories', type: :request do
    it_behaves_like "jsonapi-resources", Subcategory, {
      show: {},
      pagination: {},
      sort: {
        attribute: :name,
        sequence: -> (i) { "#{i} name" }
      }
    }
  end
end
