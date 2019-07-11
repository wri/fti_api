# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  nickname               :string
#  name                   :string
#  institution            :string
#  web_url                :string
#  is_active              :boolean          default(TRUE)
#  deactivated_at         :datetime
#  permissions_request    :integer
#  permissions_accepted   :datetime
#  country_id             :integer
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  observer_id            :integer
#  operator_id            :integer
#

require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { FactoryGirl.build :user }

  it 'is valid with valid attributes' do
    expect(user).to be_valid
  end

  it_should_behave_like 'activable', :user, FactoryGirl.build(:user)

  describe 'Enums' do
    it { is_expected.to define_enum_for(:permissions_request).with_values(
      { operator: 1, ngo: 2, ngo_manager: 4 }
    ) }
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:country).inverse_of(:users).optional }
    it { is_expected.to belong_to(:observer).optional }
    it { is_expected.to belong_to(:operator).optional }
    it { is_expected.to have_one(:api_key).dependent(:destroy) }
    it { is_expected.to have_one(:user_permission) }
    it { is_expected.to have_many(:observations).inverse_of(:user) }
    it { is_expected.to have_many(:comments).inverse_of(:user).dependent(:destroy) }
    it { is_expected.to have_many(:photos).inverse_of(:user) }
    it { is_expected.to have_many(:observation_documents).inverse_of(:user) }
    it { is_expected.to have_many(:observation_reports).inverse_of(:user) }
    it { is_expected.to have_many(:operator_document_annexes).inverse_of(:user) }
  end

  describe 'Nested attributes' do
    it { is_expected.to accept_nested_attributes_for(:user_permission) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:nickname) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:password_confirmation) }

    it { is_expected.to validate_uniqueness_of(:nickname).case_insensitive }
    it { is_expected.to validate_uniqueness_of(:email).ignoring_case_sensitivity }

    it { is_expected.to allow_value('email@email.com').for(:email).on(:update) }
    it { is_expected.not_to allow_value('change@tmp.com').for(:email).on(:update) }
    it { is_expected.to allow_value('random').for(:nickname) }
    it { is_expected.to validate_exclusion_of(:nickname).in_array(
      %w[admin superuser about root fti otp faq contact user operator ngo]
    ) }

    it { is_expected.to validate_confirmation_of(:password) }

    it { is_expected.to validate_length_of(:password).is_at_least(8).is_at_most(20).on(:create) }

    describe '#user_integrity' do
      context 'when there is not an user permission' do
        it 'add an error on user_permission' do
          user = FactoryGirl.create :user
          user.update_attribute(:user_permission, nil)

          expect(user.valid?).to eql false
          expect(user.errors[:user_permission]).to eql(
            ['You must choose a user permission']
          )
        end
      end

      context 'when user permission is operator and there is not operator' do
        it 'add an error on operator_id' do
          user_permission = FactoryGirl.create :user_permission, user_role: 1
          user = user_permission.user

          expect(user.valid?).to eql false
          expect(user.errors[:operator_id]).to eql(
            ['User of type Operator must have an operator and no observer']
          )
        end
      end

      context 'when user permission is ngo or ngo_manager and there is not observer' do
        it 'add an error on observer' do
          user_permission = FactoryGirl.create :user_permission, user_role: 2
          user = user_permission.user

          expect(user.valid?).to eql false
          expect(user.errors[:observer_id]).to eql(
            ['User of type NGO must have an observer and no operator']
          )
        end
      end

      context 'when user_permission is admin, user or bo_manager' do
        context 'when operator is present' do
          it 'add an error on operator_id' do
            operator = FactoryGirl.create :operator
            user_permission = FactoryGirl.create :user_permission, user_role: 3
            user = user_permission.user
            user.update_attributes(operator_id: operator.id)

            expect(user.valid?).to eql false
            expect(user.errors[:operator_id]).to eql(
              ['Cannot have an Operator']
            )
          end
        end

        context 'when observer is present' do
          it 'add an error on observer_id' do
            observer = FactoryGirl.create :observer
            user_permission = FactoryGirl.create :user_permission, user_role: 3
            user = user_permission.user
            user.update_attributes(observer_id: observer.id)

            expect(user.valid?).to eql false
            expect(user.errors[:observer_id]).to eql(
              ['Cannot have an Observer']
            )
          end
        end
      end
    end
  end

  describe 'Hooks' do
    describe '#create_from_request' do
      context 'when permision_request is present' do
        it 'add user_permission which correspond to the permissions_request' do
          user = FactoryGirl.build :user, permissions_request: 1

          expect(user.user_permission).not_to eql nil
          expect(user.user_permission.user_role).to eql 'user'
        end
      end
    end
  end

  describe 'Instance methods' do
    describe '#is_operator?' do
      before do
        @operator = FactoryGirl.create :operator
        @user = FactoryGirl.create :user, permissions_request: 1, operator: @operator
      end

      context 'when the user is an operator' do
        context 'when operator_id is the same which appear on the parameter' do
          it 'return true' do
            expect(@user.is_operator?(@operator.id)).to eql true
          end
        end

        context 'when operator_id is not the same which appear on the parameter' do
          it 'return false' do
            another_operator = FactoryGirl.create :operator

            expect(@user.is_operator?(another_operator.id)).to eql false
          end
        end
      end

      context 'when the user is not an operator' do
        it 'return false' do
          user = FactoryGirl.build :user, permissions_request: 2

          expect(user.is_operator?(@operator.id)).to eql false
        end
      end
    end

    describe '#display_name' do
      context 'when name is present' do
        it 'return name' do
          user = FactoryGirl.build :user, name: nil

          expect(user.send('display_name')).to eql user.send('half_email')
        end
      end

      context 'when name is blank' do
        it 'return half_email' do
          expect(user.display_name).to eql user.name
        end
      end
    end

    describe '#active_for_authentication?' do
      context 'when is_active is true' do
        it 'return true' do
          user = FactoryGirl.create :user

          expect(user.active_for_authentication?).to eql true
        end
      end

      context 'when is_active is false' do
        it 'return false' do
          user = FactoryGirl.create:user, is_active: false

          expect(user.active_for_authentication?).to eql false
        end
      end
    end

    describe '#inactive_message' do
      it 'return message "You are not allowed to sign in."' do
        expect(user.inactive_message).to eql 'You are not allowed to sign in.'
      end
    end

    describe '#api_key_exists' do
      context 'when api_key is present' do
        context 'when api_key has expired' do
          it 'return false' do
            api_key = FactoryGirl.create :api_key, expires_at: DateTime.yesterday
            user = FactoryGirl.create :user, api_key: api_key

            expect(user.api_key_exists?).to eql false
          end
        end

        context 'when api_key has not expired' do
          it 'return true' do
            api_key = FactoryGirl.create :api_key
            user = FactoryGirl.create :user, api_key: api_key

            expect(user.api_key_exists?).to eql true
          end
        end
      end

      context 'when api_key is blank' do
        it 'return nil' do
          user = FactoryGirl.create :user, api_key: nil

          expect(user.api_key_exists?).to eql nil
        end
      end
    end

    describe '#regenerate_api_key' do
      it 'create/update api_key with the information of the user' do
        user = FactoryGirl.create :user

        expect(user.api_key).to eql nil

        user.regenerate_api_key

        user.reload
        expect(user.api_key).not_to eql nil
      end
    end

    describe '#delete_api_key' do
      it 'removes all api_key associated to the user' do
        api_key = FactoryGirl.create :api_key
        user = FactoryGirl.create :user, api_key: api_key

        user.delete_api_key

        expect(APIKey.where(user_id: user.id).any?).to eql false
      end
    end

    describe '#reset_password_by_token' do
      context 'when reset_password_send_at is present and is within time' do
        it 'update the password with the specified options' do
          user = FactoryGirl.create :user, reset_password_sent_at: DateTime.current

          expect do
            user.reset_password_by_token({password: 'foobarfoo', password_confirmation: 'foobarfoo'})
          end.to change(user, :password)
        end
      end

      context 'when reset_password_send_at is not present or is too late' do
        it 'add an error on reset_password_token' do
          user = FactoryGirl.create :user

          expect do
            user.reset_password_by_token({password: 'foobarfoo', password_confirmation: 'foobarfoo'})
          end.not_to change(user, :password)
          expect(user.errors[:reset_password_token]).to eql(['link expired.'])
        end
      end
    end

    describe '#reset_password_by_current_user' do
      context 'when password and password_confirmation are valid' do
        it 'return the user instance' do
          user = FactoryGirl.create :user

          expect do
            user.reset_password_by_current_user({password: 'foobarfoo', password_confirmation: 'foobarfoo'})
          end.to change(user, :password)
        end
      end
    end

    describe '#generate_reset_token' do
      it 'generate a random reset password token' do
        user = FactoryGirl.create :user

        expect do
          user.send('generate_reset_token', user)
        end.to change(user, :reset_password_token)
      end
    end

    describe '#half_email' do
      context 'when email is blank' do
        it 'return empty string' do
          user = FactoryGirl.build :user, email: nil

          expect(user.send('half_email')).to eql ''
        end
      end

      context 'when email is present and index is greather than 0' do
        it 'return first part of the email' do
          user = FactoryGirl.build :user

          expect(user.send('half_email')).not_to eql ''
        end
      end
    end
  end

  describe 'Class methods' do
    describe '#fetch_all' do
      it 'return all users' do
        expect(User.fetch_all(nil).count).to eq(User.all.size)
      end
    end
  end
end
