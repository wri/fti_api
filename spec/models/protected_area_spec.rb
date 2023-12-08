# == Schema Information
#
# Table name: protected_areas
#
#  id         :bigint           not null, primary key
#  country_id :bigint           not null
#  name       :string           not null
#  wdpa_pid   :string           not null
#  geojson    :jsonb            not null
#  geometry   :geometry         geometry, 0
#  centroid   :geometry         point, 0
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "rails_helper"

RSpec.describe ProtectedArea, type: :model do
  subject(:protected_area) { build(:protected_area) }

  it "is valid with valid attributes" do
    expect(protected_area).to be_valid
  end

  describe "Validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:wdpa_pid) }
    it { is_expected.to validate_presence_of(:geojson) }
  end
end
