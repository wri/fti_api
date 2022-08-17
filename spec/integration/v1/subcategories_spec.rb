require 'rails_helper'

module V1
  describe 'Subcategories', type: :request do
    let(:category) { create(:category) }

    it_behaves_like "jsonapi-resources", Subcategory, {
      show: {},
      create: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: -> { { name: 'Subcategory one', 'subcategory-type': 'operator', relationships: { category: category.id } } },
        invalid_params: -> { { name: 'Subcategory one', 'subcategory-type': '', relationships: { category: category.id } } },
        error_attributes: [422, 100, { 'subcategory-type': ["can't be blank"] }]
      },
      edit: {
        success_roles: %i[admin],
        failure_roles: %i[user],
        valid_params: -> { { name: 'Subcategory one', 'subcategory-type': 'operator', relationships: { category: category.id } } },
        invalid_params: -> { { name: 'Subcategory one', 'subcategory-type': '', relationships: { category: category.id } } },
        error_attributes: [422, 100, { 'subcategory-type': ["can't be blank"] }]
      },
      delete: {
        success_roles: %i[admin],
        failure_roles: %i[user]
      },
      pagination: {},
      sort: {
        attribute: :name,
        sequence: -> (i) { "#{i} name" }
      }
    }
  end
end
