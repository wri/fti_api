# == Schema Information
#
# Table name: user_permissions
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  user_role   :integer          default("user"), not null
#  permissions :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require "rails_helper"
require "cancan/matchers"

RSpec.describe UserPermission, type: :model do
  subject(:user_permission) { build(:user_permission) }

  it "is valid with valid attributes" do
    expect(user_permission).to be_valid
  end

  # TODO: Add more tests for permissions
  describe "Permissions" do
    subject(:ability) { Ability.new(user) }

    before(:all) do
      @observer1 = create(:observer)
      @observer2 = create(:observer)

      report1 = create(:observation_report, observers: [@observer1])
      report2 = create(:observation_report, observers: [@observer2])
      @observation1 = create(:observation, observation_report: report1)
      @observation2 = create(:observation, observation_report: report2)
    end

    describe "bo_manager" do
      let(:user) { create(:bo_manager, qc1_observers: [@observer1]) }

      it { is_expected.to be_able_to(:manage, user) }
      it { is_expected.to be_able_to(:cru, QualityControl.new(reviewable: @observation1)) }
      it { is_expected.not_to be_able_to(:delete, QualityControl.new(reviewable: @observation1)) }
      it { is_expected.not_to be_able_to(:cru, QualityControl.new(reviewable: @observation2)) }
      it { is_expected.not_to be_able_to(:delete, QualityControl.new(reviewable: @observation2)) }
      it { is_expected.not_to be_able_to(:delete, QualityControl.new) }
    end

    describe "ngo_manager" do
      let(:user) { create(:ngo_manager, qc1_observers: [@observer1]) }

      it { is_expected.to be_able_to(:manage, user) }
      it { is_expected.to be_able_to(:cru, QualityControl.new(reviewable: @observation1)) }
      it { is_expected.not_to be_able_to(:delete, QualityControl.new(reviewable: @observation1)) }
      it { is_expected.not_to be_able_to(:cru, QualityControl.new(reviewable: @observation2)) }
      it { is_expected.not_to be_able_to(:delete, QualityControl.new(reviewable: @observation2)) }
      it { is_expected.not_to be_able_to(:delete, QualityControl.new) }
    end
  end
end
