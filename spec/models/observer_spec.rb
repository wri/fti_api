# == Schema Information
#
# Table name: observers
#
#  id                :integer          not null, primary key
#  observer_type     :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_active         :boolean          default(TRUE)
#  logo              :string
#  address           :string
#  information_name  :string
#  information_email :string
#  information_phone :string
#  data_name         :string
#  data_email        :string
#  data_phone        :string
#  organization_type :string
#

require 'rails_helper'

RSpec.describe Observer, type: :model do
  before :each do
    FactoryGirl.create(:observer, name: 'Z Observer')
    @monitor = create(:observer)
  end

  it 'Count on observer' do
    expect(Observer.count).to          eq(2)
    expect(Observer.all.first.name).to eq('Z Observer')
  end

  it 'Order by name asc' do
    expect(Observer.by_name_asc.first.name).to match('Observer')
  end

  it 'Fallbacks for empty translations on observer' do
    I18n.locale = :fr
    expect(@monitor.name).to match('Observer')
    I18n.locale = :en
  end

  it 'Translate observer to fr' do
    @monitor.update(name: 'Observer FR', locale: :fr)
    I18n.locale = :fr
    expect(@monitor.name).to eq('Observer FR')
    I18n.locale = :en
    expect(@monitor.name).to match('Observer')
  end

  it 'Name and observer_type validation' do
    @monitor = Observer.new(name: '', observer_type: '')

    @monitor.valid?
    expect { @monitor.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank, Observer type can't be blank, Observer type  is not a valid observer type")
  end

  it 'Observer_type validation' do
    @monitor = Observer.new(name: 'Observer new', observer_type: 'Not in types')

    @monitor.valid?
    expect { @monitor.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Observer type Not in types is not a valid observer type")
  end

  it 'Fetch all monitors' do
    expect(Observer.fetch_all(nil).count).to eq(2)
  end

  it 'Monitor select' do
    expect(Observer.observer_select.size).to eq(2)
  end
end
