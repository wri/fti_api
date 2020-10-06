# == Schema Information
#
# Table name: contributors
#
#  id          :integer          not null, primary key
#  website     :string
#  logo        :string
#  priority    :integer
#  category    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  type        :string           default("Partner")
#  name        :string           not null
#  description :text
#

require 'rails_helper'

RSpec.describe Contributor, type: :model do
  subject(:contributor) { FactoryBot.build(:contributor) }

  it 'is valid with valid attributes' do
    expect(contributor).to be_valid
  end

  it_should_behave_like 'translatable', FactoryBot.create(:contributor), %i[name description]
end
