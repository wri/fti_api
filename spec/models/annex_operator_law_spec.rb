# == Schema Information
#
# Table name: annex_operator_laws
#
#  id                :integer          not null, primary key
#  annex_operator_id :integer
#  law_id            :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'rails_helper'

RSpec.describe AnnexOperatorLaw, type: :model do
  before :each do
    @annex_operator = create(:annex_operator)
    @law            = create(:law, annex_operators: [@annex_operator])
  end

  it 'Count on law annex_operator' do
    expect(@law.annex_operators.count).to eq(1)
  end
end
