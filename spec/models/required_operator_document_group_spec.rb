# == Schema Information
#
# Table name: required_operator_document_groups
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  position   :integer
#  name       :string
#

require 'rails_helper'

RSpec.describe RequiredOperatorDocumentGroup, type: :model do
  subject(:required_operator_document_group) { FactoryBot.build(:required_operator_document_group) }

  it 'is valid with valid attributes' do
    expect(required_operator_document_group).to be_valid
  end

  it_should_behave_like 'translatable', :required_operator_document_group, %i[name]
end
