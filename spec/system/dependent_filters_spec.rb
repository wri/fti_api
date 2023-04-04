require 'system_helper'

RSpec.describe 'Admin: Dependent Filters', type: :system do
  let(:admin) { create(:admin) }

  let!(:country1) { create(:country) }
  let!(:country2) { create(:country) }
  let!(:observer1) { create(:observer, countries: [country1]) }
  let!(:observer2) { create(:observer, countries: [country1]) }
  let!(:observer3) { create(:observer, countries: [country1], is_active: false) }
  let!(:observer4) { create(:observer, countries: [country2]) }

  before do
    sign_in admin
    visit '/admin/monitors'
  end

  it 'filters dependent select - test all features' do
    # match all observers
    expect(select2_options(from: 'Name')).to match_array([observer1.name, observer2.name, observer3.name, observer4.name])
    # selecting country2 should match only observer 4
    select2(country2.name, from: 'Country')
    expect(select2_options(from: 'Name')).to match_array([observer4.name])
    # select observer 4
    select2(observer4.name, from: 'Name')
    expect(select2_selected_options(from: 'Name')).to match_array([observer4.name])
    # selecting country1 should clear observer(name) selection and match only observers 1, 2 and 3
    select2(country1.name, from: 'Country')
    expect(select2_selected_options(from: 'Name')).to match_array([''])
    expect(select2_options(from: 'Name')).to match_array([observer1.name, observer2.name, observer3.name])
    # select not active observer
    select2(observer3.name, from: 'Name')
    # change is active to false
    select2('No', from: 'Is active')
    # should keep the observer selected, but available options should be only observer 3
    expect(select2_selected_options(from: 'Name')).to match_array([observer3.name])
    expect(select2_options(from: 'Name')).to match_array([observer3.name])
    select2_clear(from: 'Is active')
    select2_clear(from: 'Country')
    # should keep the observer selected, but available options should be all observers
    expect(select2_selected_options(from: 'Name')).to match_array([observer3.name])
    expect(select2_options(from: 'Name')).to match_array([observer1.name, observer2.name, observer3.name, observer4.name])
  end
end
