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
end
