# == Schema Information
#
# Table name: subcategories
#
#  id                :integer          not null, primary key
#  category_id       :integer
#  subcategory_type  :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  location_required :boolean          default(TRUE)
#  name              :text
#  details           :text
#

require 'rails_helper'

RSpec.describe Subcategory, type: :model do
  subject(:subcategory) { FactoryBot.build(:subcategory) }

  it 'is valid with valid attributes' do
    expect(subcategory).to be_valid
  end

  it_should_behave_like 'translatable', :subcategory, %i[name details]

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:subcategory_type) }
  end
end
