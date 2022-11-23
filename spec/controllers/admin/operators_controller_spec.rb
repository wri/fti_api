require 'rails_helper'

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::ProducersController, type: :controller do
  let(:admin) { create(:admin) }

  render_views

  before { sign_in admin }

  describe 'PUT activate' do
    let!(:operator) { create(:operator, is_active: false) }

    subject { put :activate, params: {id: operator.id} }

    before { subject }

    it 'is successful' do
      expect(flash[:notice]).to match('Producer activated')
      expect(operator.reload.is_active).to be(true)
    end
  end

  describe 'PUT deactivate' do
    let!(:operator) { create(:operator, is_active: true) }

    subject { put :deactivate, params: {id: operator.id} }

    before { subject }

    it 'is successful' do
      expect(flash[:notice]).to match('Producer deactivated')
      expect(operator.reload.is_active).to be(false)
    end
  end
end
