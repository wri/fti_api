# == Schema Information
#
# Table name: required_operator_document_groups
#
#  id                                  :integer          not null, primary key
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  position                            :integer
#  required_operator_document_group_id :integer          not null
#  name                                :string
#

require 'rails_helper'

RSpec.describe RequiredOperatorDocumentGroup, type: :model do
  subject(:required_operator_document_group) { FactoryBot.build(:required_operator_document_group) }

  it 'is valid with valid attributes' do
    expect(required_operator_document_group).to be_valid
  end

  it_should_behave_like 'translatable', FactoryBot.create(:required_operator_document_group), %i[name]

  describe 'Relations' do
    it { is_expected.to have_many(:required_operator_documents).dependent(:destroy) }
    it { is_expected.to have_many(:required_operator_document_countries) }
    it { is_expected.to have_many(:required_operator_document_fmus) }
  end
end
