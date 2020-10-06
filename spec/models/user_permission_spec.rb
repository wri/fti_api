# == Schema Information
#
# Table name: user_permissions
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  user_role   :integer          default("0"), not null
#  permissions :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe UserPermission, type: :model do
  before :all do
    @user = create(:user)
  end

  subject(:user_permission) { FactoryBot.build(:user_permission) }

  let(:admin_permissions) {
    { admin: { manage: {} }, all: { manage: {} } }
  }

  let(:operator_permissions) {
    { user: { manage: { id: @user.id } } , operator_document: { manage: { operator_id: @user.operator_id } },
      operator_document_annex: { ud: { operator_document: { operator_id: @user.operator_id }}, create: {}},
      observation: { read: {} }, fmu: { ru: {} }, operator: { ru: { id: @user.operator_id } },
      sawmill: { create: {}, ud: { operator_id: @user.operator_id }}}
  }

  let(:ngo_permissions) {
    { user: { manage: { id: @user.id } },
      observation: { manage: { observers: { id: @user.observer_id } },  create: {} },
      observation_report: { update: { observers: { id: @user.observer_id } }, create: {} },
      observation_documents:  { ud: { observation: { is_active: false, observers: { id: @user.observer_id } } }, create: {} },
      category: { read: {} },
      subcategory: { read: {} },
      government: { read: {} },
      species: { read: {} },
      operator: { create: {}, read: {} },
      law: { read: {} },
      severity: { read: {} },
      observer: { read: {} ,  update: { id: @user.observer_id } },
      fmu: { read: {} },
      operator_document: { read: {} },
      required_operator_document_group: { read: {} },
      required_operator_document: { read: {} } }
  }

  let(:ngo_manager_permissions) {
    {
      user: { manage: { id: @user.id } },
      observation: { manage: { observers: { id: @user.observer_id } },  create: {} },
      observation_report: { update: { observers: { id: @user.observer_id } }, create: {} },
      observation_documents:  { ud: { observation: { is_active: false, observers: { id: @user.observer_id } } }, create: {} },
      category: { cru: {} },
      subcategory: { cru: {} },
      government: { cru: {} },
      species: { cru: {} },
      operator: { cru: {} },
      law: { cru: {} },
      severity: { cru: {} },
      observer: { read: {} ,  update: { id: @user.observer_id } },
      fmu: { read: {}, update: {} },
      operator_document: { manage: {} },
      required_operator_document_group: { cru: {} },
      required_operator_document: { cru: {} },
      file_data_import: { manage: {} }
    }
  }

  let(:bo_manager_permissions) {
    {
      user: { manage: { id: @user.id } },
      observation: { manage: {} },
      observer: { read: {} },
      operator: { read: {} },
      observation_report: { read: {} },
      observation_documents:  { read: {} },
      category: { read: {} },
      subcategory: { read: {} },
      government: { read: {} },
      species: { read: {} },
      law: { read: {} },
      severity: { read: {} },
      fmu: { read: {} },
      operator_document: { read: {} },
      required_operator_document_group: { read: {} },
      required_operator_document: { read: {} }
    }
  }

  let(:user_permissions) {
    { user: { current: { id: @user.id }, read: { id: @user.id } }, observations: { read: {} } }
  }

  it 'is valid with valid attributes' do
    expect(user_permission).to be_valid
  end

  describe 'Hooks' do
    describe '#change_permissions' do
      %i[admin operator ngo ngo_manager bo_manager user].each do |role|
        context "when user_role is #{role}" do
          it "set permissions to #{role} role permissions" do
            user_permission = create(:user_permission, user_role: role, user: @user)
            expect(user_permission.permissions).to eql(
              send("#{role}_permissions").with_indifferent_access
            )
          end
        end
      end
    end
  end
end
