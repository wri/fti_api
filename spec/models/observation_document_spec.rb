# == Schema Information
#
# Table name: observation_documents
#
#  id             :integer          not null, primary key
#  name           :string
#  attachment     :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :integer
#  deleted_at     :datetime
#  observation_id :integer
#

require 'rails_helper'

RSpec.describe ObservationDocument, type: :model do
  it 'is valid with valid attributes' do
    observation_document = build(:observation_document)
    expect(observation_document).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:user).inverse_of(:observation_documents).touch(true) }
    it { is_expected.to belong_to(:observation).inverse_of(:observation_documents).touch(true) }
  end

  describe 'Hooks' do
    describe '#remove_attachment_id_directory' do
      it 'removes all attached documents' do
        observation_document = create(:observation_document)
        filepath = File.join(
          'spec',
          'support',
          'uploads',
          'observation_document',
          'attachment',
          observation_document.id.to_s,
          'image.png'
        )

        expect(File.exist?(filepath)).to eql true

        observation_document.destroy

        expect(File.exist?(filepath)).to eql false
      end
    end
  end
end
