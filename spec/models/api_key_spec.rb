# == Schema Information
#
# Table name: api_keys
#
#  id           :integer          not null, primary key
#  access_token :string
#  expires_at   :datetime
#  user_id      :integer
#  is_active    :boolean          default(TRUE)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require "rails_helper"

RSpec.describe APIKey, type: :model do
  subject(:api_key) { FactoryBot.build(:api_key) }

  it "is valid with valid attributes" do
    expect(api_key).to be_valid
  end

  context "Relations" do
    it { is_expected.to belong_to(:user) }
  end

  context "Methods" do
    describe "#expired?" do
      context "when APIKey expires_at date is lower than current date" do
        it "returns true" do
          api_key = create(:api_key, expires_at: Date.yesterday)
          expect(api_key.expired?).to eql true
        end
      end

      context "when user is deactivated" do
        it "returns true" do
          user = create(:admin)
          user.deactivate
          api_key = build(:api_key, user: user, expires_at: Date.yesterday)
          expect(api_key.expired?).to eql true
        end
      end

      context "when APIKey is deactivated" do
        it "returns true" do
          api_key = create(:api_key)
          api_key.deactivate
          expect(api_key.expired?).to eql true
        end
      end

      context "when APIKey has not expired" do
        it "returns false" do
          api_key = create(:api_key)
          expect(api_key.expired?).to eql false
        end
      end
    end
  end

  it_should_behave_like "activable", :api_key, FactoryBot.create(:api_key)
end
