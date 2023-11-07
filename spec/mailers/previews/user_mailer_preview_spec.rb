require "rails_helper"

describe UserMailerPreview, type: :request do
  describe "user_acceptance_observer" do
    before { create(:ngo) }

    it_behaves_like "mail_preview", with_locales: %w[en fr]
  end

  describe "user_acceptance_operator" do
    before { create(:operator_user) }
  end

  describe "forgotten_password" do
    before { create(:operator_user) }
  end
end
