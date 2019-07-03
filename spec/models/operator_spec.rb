# == Schema Information
#
# Table name: operators
#
#  id                                 :integer          not null, primary key
#  operator_type                      :string
#  country_id                         :integer
#  concession                         :string
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  is_active                          :boolean          default(TRUE)
#  logo                               :string
#  operator_id                        :string
#  percentage_valid_documents_all     :float
#  percentage_valid_documents_country :float
#  percentage_valid_documents_fmu     :float
#  score_absolute                     :float
#  score                              :integer
#  obs_per_visit                      :float
#  fa_id                              :string
#  address                            :string
#  website                            :string
#  country_doc_rank                   :integer
#  country_operators                  :integer
#  approved                           :boolean          default(TRUE), not null
#

require 'rails_helper'

RSpec.describe Operator, type: :model do
  before :each do
    FactoryGirl.create(:operator, name: 'Z Operator')
    @operator = create(:operator)
  end

  it 'Count on operator' do
    expect(Operator.count).to          eq(2)
    expect(Operator.all.first.name).to eq('Z Operator')
  end

  it 'Order by name asc' do
    expect(Operator.by_name_asc.first.name).to match('Operator')
  end

  it 'Fallbacks for empty translations on operator' do
    I18n.locale = :fr
    expect(@operator.name).to match('Operator')
    I18n.locale = :en
  end

  it 'Translate operator to fr' do
    @operator.update(name: 'Operator FR', locale: :fr)
    I18n.locale = :fr
    expect(@operator.name).to eq('Operator FR')
    I18n.locale = :en
    expect(@operator.name).to match('Operator')
  end

  it 'Name validation' do
    @operator = Operator.new(name: '')

    @operator.valid?
    expect { @operator.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank")
  end

  it 'Fetch all operators' do
    expect(Operator.fetch_all(nil).count).to eq(2)
  end

  it 'Operator select' do
    expect(Operator.operator_select.size).to eq(2)
  end
end
