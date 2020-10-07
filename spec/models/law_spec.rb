# == Schema Information
#
# Table name: laws
#
#  id                 :integer          not null, primary key
#  written_infraction :text
#  infraction         :text
#  sanctions          :text
#  min_fine           :integer
#  max_fine           :integer
#  penal_servitude    :string
#  other_penalties    :text
#  apv                :text
#  subcategory_id     :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  country_id         :integer
#  currency           :string
#

require 'rails_helper'

RSpec.describe Law, type: :model do
  subject(:law) { FactoryBot.build(:law) }

  it 'is valid with valid attributes' do
    expect(law).to be_valid
  end
end
