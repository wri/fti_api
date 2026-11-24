# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::UsersController, type: :controller do
  let(:admin) { create(:admin) }
  let!(:user) { create(:user) }

  render_views

  context "when signed in as super admin" do
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

    describe "PUT update" do
      it "changes role and active status of another user" do
        put :update, params: {id: user.id, user: {is_active: false, user_permission_attributes: {id: user.user_permission.id, user_role: "bo_manager"}}}

        user.reload
        expect(user.user_permission.user_role).to eq("bo_manager")
        expect(user.is_active).to be(false)
      end

      it "ignores own role and active status" do
        put :update, params: {id: admin.id, user: {first_name: "Changed", is_active: false, user_permission_attributes: {id: admin.user_permission.id, user_role: "user"}}}

        admin.reload
        expect(admin.first_name).to eq("Changed")
        expect(admin.user_permission.user_role).to eq("admin")
        expect(admin.is_active).to be(true)
      end
    end

    describe "GET edit" do
      it "shows role and active inputs for another user" do
        get :edit, params: {id: user.id}

        expect(response.body).to include("user_user_permission_attributes_user_role")
        expect(response.body).to include("user_is_active")
      end

      it "hides role and active inputs for own record" do
        get :edit, params: {id: admin.id}

        expect(response).to be_successful
        expect(response.body).not_to include("user_user_permission_attributes_user_role")
        expect(response.body).not_to include("user_is_active")
      end
    end
  end

  context "when signed in as bo_manager" do
    let(:bo_manager) { create(:bo_manager) }

    before { sign_in bo_manager }

    it "can edit own profile without privileged inputs" do
      get :edit, params: {id: bo_manager.id}

      expect(response).to be_successful
      expect(response.body).not_to include("user_user_permission_attributes_user_role")
      expect(response.body).not_to include("user_is_active")
      expect(response.body).not_to include("user_responsible_for_country_ids")
      expect(response.body).not_to include("user_qc1_observer_ids")
    end

    it "cannot change own role or privileged attributes" do
      country = create(:country)
      put :update, params: {id: bo_manager.id, user: {
        first_name: "Changed",
        responsible_for_country_ids: [country.id],
        user_permission_attributes: {id: bo_manager.user_permission.id, user_role: "admin"}
      }}

      bo_manager.reload
      expect(bo_manager.first_name).to eq("Changed")
      expect(bo_manager.user_permission.user_role).to eq("bo_manager")
      expect(bo_manager.responsible_for_countries).to be_empty
    end

    context "with a permissions override granting user management" do
      before { bo_manager.user_permission.update!(permissions: {user: {manage: {}}}) }

      it "cannot update another user" do
        put :update, params: {id: admin.id, user: {email: "taken-over@example.com"}}

        expect(response).to redirect_to(admin_dashboard_path)
        expect(admin.reload.email).not_to eq("taken-over@example.com")
      end
    end
  end
end
