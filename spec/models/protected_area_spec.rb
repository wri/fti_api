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
