# == Schema Information
#
# Table name: categorings
#
#  id                 :integer          not null, primary key
#  category_id        :integer          not null
#  categorizable_id   :integer
#  categorizable_type :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

require 'rails_helper'

RSpec.describe Categoring, type: :model do
  before :each do
    @category = create(:category)
    @annex    = create(:annex_operator)
  end

  it 'Relate category with annex' do
    @categoring = Categoring.create(categorizable: @annex, category: @category)
    expect(@categoring.valid?).to eq(true)
    expect(@categoring.category.annex_operators.size).to eq(1)
    expect(AnnexOperator.all.last.categories.size).to    eq(1)
  end

  it 'Build categoring' do
    @categoring = Categoring.build(@annex, @category)
    expect(@categoring.categorizable_type).to match('AnnexOperator')
  end
end
