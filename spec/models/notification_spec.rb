# == Schema Information
#
# Table name: notifications
#
#  id                    :integer          not null, primary key
#  last_displayed_at     :datetime
#  dismissed_at          :datetime
#  solved_at             :datetime
#  operator_document_id  :integer          not null
#  user_id               :integer          not null
#  notification_group_id :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
require 'rails_helper'

RSpec.describe Notification, type: :model do
  subject { notification }
  context 'when no mandatory fields are missing' do
    let(:notification) { build :notification }
    it { is_expected.to be_valid }
  end

  context 'when there is no notification group' do
    let(:notification) { build :notification, notification_group: nil }
    it { is_expected.to be_valid }
  end

  context 'when there is no user_id' do
    let(:notification) { build :notification, user: nil }
    it { is_expected.not_to be_valid }
    it { expect{ subject.valid? }.to change { subject.errors&.messages&.first }.from(nil).to([:user, ['must exist']])}
  end

  context 'when there is no operator document' do
    let(:notification) { build :notification, operator_document: nil }
    it { is_expected.not_to be_valid }
    it { expect{ subject.valid? }.to change { subject.errors&.messages&.first }.from(nil).to([:operator_document, ['must exist']])}
  end
end
