# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::UsersController, type: :controller do
  let(:admin) { create(:admin) }
  let!(:user) { create(:user) }

  render_views

  before { sign_in admin }

  describe "PUT unlock" do
    before do
      user.lock_access!(send_instructions: false)
      put :unlock, params: {id: user.id}
    end

    it "unlocks the user" do
      expect(flash[:notice]).to eq(I18n.t("active_admin.shared.user_unlocked"))
      expect(user.reload).not_to be_access_locked
      expect(user.failed_attempts).to eq(0)
      expect(user.unlock_token).to be_nil
    end
  end

  describe "GET index" do
    before { user.lock_access!(send_instructions: false) }

    it "includes the Locked scope" do
      get :index, params: {scope: "access_locked"}

      expect(response).to be_successful
      expect(response.body).to include(user.email)
      expect(response.body).to include(I18n.t("active_admin.shared.locked"))
      expect(response.body).to include(I18n.t("active_admin.shared.unlock"))
    end
  end
end
