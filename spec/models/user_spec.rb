# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string
#  is_active              :boolean          default(TRUE), not null
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
#  holding_id             :integer
#  locale                 :string
#  first_name             :string
#  last_name              :string
#  organization_account   :boolean          default(FALSE), not null
#

require "rails_helper"

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  it "is valid with valid attributes" do
    expect(user).to be_valid
  end

  it_should_behave_like "activable", :user, FactoryBot.create(:user)

  describe "Nested attributes" do
    it { is_expected.to accept_nested_attributes_for(:user_permission) }
  end

  describe "Validations" do
    # TODO: reenable later when validating first/last names
    #  it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:user_permission) }

    it { is_expected.to validate_uniqueness_of(:email).ignoring_case_sensitivity }

    it { is_expected.to allow_value("email@email.com").for(:email).on(:update) }

    it { is_expected.to validate_confirmation_of(:password) }

    it { is_expected.to validate_length_of(:password).is_at_least(10).is_at_most(128) }

    it "is invalid when password does not contain lowercase letter" do
      subject.password = "PASSWORD1234"
      subject.password_confirmation = "PASSWORD1234"
      expect(subject.valid?).to eq(false)
      expect(subject.errors[:password]).to include("must contain at least one uppercase letter, one lowercase letter, and one digit")
    end

    it "is invalid when password does not contain uppercase letter" do
      subject.password = "password1234"
      subject.password_confirmation = "password1234"
      expect(subject.valid?).to eq(false)
      expect(subject.errors[:password]).to include("must contain at least one uppercase letter, one lowercase letter, and one digit")
    end

    it "is invalid when password does not contain digit" do
      subject.password = "SuperPassword"
      subject.password_confirmation = "SuperPassword"
      expect(subject.valid?).to eq(false)
      expect(subject.errors[:password]).to include("must contain at least one uppercase letter, one lowercase letter, and one digit")
    end

    describe "user permissions" do
      let(:user) { build(:user, user_role: user_role) }

      context "with operator role" do
        let(:user_role) { "operator" }

        context "when there is no operator" do
          it "add an error on operator" do
            expect(user.valid?).to eql false
            expect(user.errors[:operator]).to eql(["can't be blank"])
          end
        end
      end

      context "with ngo role" do
        let(:user_role) { "ngo" }

        context "when there is no observer" do
          it "add an error on observer" do
            expect(user.valid?).to eql false
            expect(user.errors[:observer]).to eql(["can't be blank"])
          end
        end
      end

      context "with ngo role" do
        let(:user_role) { "ngo_manager" }

        context "when there is no observer" do
          it "add an error on observer" do
            expect(user.valid?).to eql false
            expect(user.errors[:observer]).to eql(["can't be blank"])
          end
        end
      end

      context "with holding role" do
        let(:user_role) { "holding" }

        context "when there is no holding" do
          it "add an error on holding" do
            expect(user.valid?).to eql false
            expect(user.errors[:holding]).to eql(["can't be blank"])
          end
        end
      end
    end
  end

  describe "Hooks" do
    describe "#clear_unrelated_relations" do
      let(:user) { build(:user, operator: build(:operator), observer: build(:observer), holding: build(:holding), permissions_request: user_role) }

      context "when user_permission is operator" do
        let(:user_role) { "operator" }

        it "clears observer and holding" do
          expect(user.valid?).to eql true
          expect(user.observer).to eql nil
          expect(user.holding).to eql nil
        end
      end

      context "when user_permission is ngo" do
        let(:user_role) { "ngo" }

        it "clears operator and holding" do
          expect(user.valid?).to eql true
          expect(user.operator).to eql nil
          expect(user.holding).to eql nil
        end
      end

      context "when user_permission is ngo_manager" do
        let(:user_role) { "ngo_manager" }

        it "clears operator and holding" do
          expect(user.valid?).to eql true
          expect(user.operator).to eql nil
          expect(user.holding).to eql nil
        end
      end

      context "when user_permission is holding" do
        let(:user_role) { "holding" }

        it "clears operator and observer" do
          expect(user.valid?).to eql true
          expect(user.operator).to eql nil
          expect(user.observer).to eql nil
        end
      end

      context "when user_permission is government" do
        let(:user_role) { "government" }

        it "clears operator, observer, holding" do
          expect(user.valid?).to eql true
          expect(user.operator).to eql nil
          expect(user.observer).to eql nil
          expect(user.holding).to eql nil
        end
      end
    end

    describe "#create_from_request" do
      context "when permission_request is present" do
        it "add user_permission which correspond to the permissions_request" do
          user = build(:user, permissions_request: 1)

          expect(user.user_permission).not_to eql nil
          expect(user.user_permission.user_role).to eql "user"
        end
      end
    end
    describe "sends notification email to the user" do
      context "when the active flag is not changed" do
        it "doesn't send the email" do
          created_user = FactoryBot.create(:user, is_active: false)
          created_user.name = "new name"
          expect { created_user.save }.not_to have_enqueued_mail(UserMailer, :user_acceptance)
        end
      end
      context "when the active flag is changed to false" do
        it "doesn't send the email" do
          created_user = FactoryBot.create(:user, is_active: true)
          created_user.is_active = false
          expect { created_user.save }.not_to have_enqueued_mail(UserMailer, :user_acceptance)
        end
      end
      context "when the active flag is changed to true" do
        it "sends the email" do
          created_user = FactoryBot.create(:user, is_active: false)
          created_user.is_active = true
          expect { created_user.save }.to have_enqueued_mail(UserMailer, :user_acceptance)
        end
      end
    end
  end

  describe "Instance methods" do
    describe "#is_operator?" do
      before do
        @operator = create(:operator)
        @user = create(:user, permissions_request: 1, operator: @operator)
      end

      context "when the user is an operator" do
        context "when operator_id is the same which appear on the parameter" do
          it "return true" do
            expect(@user.is_operator?(@operator.id)).to eql true
          end
        end

        context "when operator_id is not the same which appear on the parameter" do
          it "return false" do
            another_operator = create(:operator)

            expect(@user.is_operator?(another_operator.id)).to eql false
          end
        end
      end

      context "when the user is not an operator" do
        it "return false" do
          user = build(:user, permissions_request: 2)

          expect(user.is_operator?(@operator.id)).to eql false
        end
      end
    end

    describe "#display_name" do
      context "when name is present" do
        it "return name" do
          user = build(:user, first_name: nil, last_name: nil)

          expect(user.send(:display_name)).to eql user.send(:half_email)
        end
      end

      context "when name is blank" do
        it "return half_email" do
          expect(user.display_name).to eql user.name
        end
      end
    end

    describe "#active_for_authentication?" do
      context "when is_active is true" do
        it "return true" do
          user = create(:user)

          expect(user.active_for_authentication?).to eql true
        end
      end

      context "when is_active is false" do
        it "return false" do
          user = create(:user, is_active: false)

          expect(user.active_for_authentication?).to eql false
        end
      end
    end

    describe "#inactive_message" do
      it 'return message "You are not allowed to sign in."' do
        expect(user.inactive_message).to eql "You are not allowed to sign in."
      end
    end

    describe "#api_key_exists" do
      context "when api_key is present" do
        context "when api_key has expired" do
          it "return false" do
            api_key = create(:api_key, expires_at: DateTime.yesterday)
            user = create(:user, api_key: api_key)

            expect(user.api_key_exists?).to eql false
          end
        end

        context "when api_key has not expired" do
          it "return true" do
            api_key = create(:api_key)
            user = create(:user, api_key: api_key)

            expect(user.api_key_exists?).to eql true
          end
        end
      end

      context "when api_key is blank" do
        it "return nil" do
          user = create(:user, api_key: nil)

          expect(user.api_key_exists?).to eql nil
        end
      end
    end

    describe "#regenerate_api_key" do
      it "create/update api_key with the information of the user" do
        user = create(:user)

        expect(user.api_key).to eql nil

        user.regenerate_api_key

        user.reload
        expect(user.api_key).not_to eql nil
      end
    end

    describe "#delete_api_key" do
      it "removes all api_key associated to the user" do
        api_key = create(:api_key)
        user = create(:user, api_key: api_key)

        user.delete_api_key

        expect(APIKey.where(user_id: user.id).any?).to eql false
      end
    end

    describe "#generate_reset_token" do
      it "generate a random reset password token" do
        user = create(:user)

        expect do
          user.send(:generate_reset_token, user)
        end.to change(user, :reset_password_token)
      end
    end

    describe "#half_email" do
      context "when email is blank" do
        it "return empty string" do
          user = build(:user, email: nil)

          expect(user.send(:half_email)).to eql ""
        end
      end

      context "when email is present and index is greather than 0" do
        it "return first part of the email" do
          user = build(:user)

          expect(user.send(:half_email)).not_to eql ""
        end
      end
    end
  end
end
