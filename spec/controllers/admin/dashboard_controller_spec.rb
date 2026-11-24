# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::DashboardController, type: :controller do
  describe "POST change_language" do
    let(:bo_manager) { create(:bo_manager, locale: "en") }

    before { sign_in bo_manager }

    it "lets bo_manager change own language" do
      post :change_language, params: {locale: "fr"}

      expect(flash[:alert]).to be_nil
      expect(bo_manager.reload.locale).to eq("fr")
    end
  end
end
