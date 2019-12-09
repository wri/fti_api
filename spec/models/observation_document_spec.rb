require 'rails_helper'

RSpec.describe ObservationDocument, type: :model do
  it 'is valid with valid attributes' do
    observation_document = FactoryBot.build :observation_document
    expect(observation_document).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:user).inverse_of(:observation_documents).touch(true) }
    it { is_expected.to belong_to(:observation).inverse_of(:observation_documents).touch(true) }
  end

  describe 'Hooks' do
    describe '#remove_attachment_id_directory' do
      it 'removes all attached documents' do
        observation_document = FactoryBot.create :observation_document
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
