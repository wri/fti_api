require 'rails_helper'
require 'cancan/matchers'

RSpec.describe Ability, type: :model do
  describe 'Ability' do
    context 'Global settings' do
      it { expect(Ability).to include(CanCan::Ability)          }
      it { expect(Ability).to respond_to(:new).with(1).argument }
    end

    context 'When is a user' do
      before :each do
        @user  = create(:user)
      end

      it 'Can manage owned profile' do
        expect_any_instance_of(Ability).to receive(:can).with([:read], Observation)
        expect_any_instance_of(Ability).to receive(:can).with([:manage], User, id: @user.id)
        expect_any_instance_of(Ability).to receive(:cannot).with([:activate, :deactivate, :destroy], User, id: @user.id)
        expect_any_instance_of(Ability).to receive(:cannot).with([:edit, :update], UserPermission, user_id: @user.id)
        Ability.new @user
      end
    end

    context 'When is an admin' do
      before :each do
        @admin = create(:admin)
      end

      it 'Can manage all' do
        expect_any_instance_of(Ability).to receive(:can).with([:read], :admin)
        expect_any_instance_of(Ability).to receive(:can).with([:manage], :all)
        expect_any_instance_of(Ability).to receive(:cannot).with([:activate, :deactivate, :destroy], User, id: @admin.id)
        expect_any_instance_of(Ability).to receive(:cannot).with([:edit, :update], UserPermission, user_id: @admin.id)
        Ability.new @admin
      end
    end

    context 'When is an ngo user' do
      before :each do
        @ngo = create(:ngo)
      end

      it 'Can manage observations' do
        expect_any_instance_of(Ability).to receive(:can).with([:manage], Observation, user_id: @ngo.id)
        expect_any_instance_of(Ability).to receive(:can).with([:manage], User, id: @ngo.id)
        expect_any_instance_of(Ability).to receive(:cannot).with([:activate, :deactivate, :destroy], User, id: @ngo.id)
        expect_any_instance_of(Ability).to receive(:cannot).with([:edit, :update], UserPermission, user_id: @ngo.id)
        Ability.new @ngo
      end
    end

    context 'When is an deactivated user' do
      before :each do
        @deactivated_user = create(:user, is_active: false)
      end

      it 'Can read all' do
        expect_any_instance_of(Ability).to receive(:can).with([:read], User, id: @deactivated_user.id)
        Ability.new @deactivated_user
      end
    end
  end
end
