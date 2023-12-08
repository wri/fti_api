# == Schema Information
#
# Table name: species
#
#  id              :integer          not null, primary key
#  name            :string
#  species_class   :string
#  sub_species     :string
#  species_family  :string
#  species_kingdom :string
#  scientific_name :string
#  cites_status    :string
#  cites_id        :integer
#  iucn_status     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  common_name     :string
#

require "rails_helper"

RSpec.describe Species, type: :model do
  subject(:species) { FactoryBot.build(:species) }

  it "is valid with valid attributes" do
    expect(species).to be_valid
  end

  it_should_behave_like "translatable", :species, %i[common_name]

  describe "Validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "Instance methods" do
    describe "#cache_key" do
      it "return the default value with the locale" do
        expect(species.cache_key).to match(/-#{Globalize.locale}\z/)
      end
    end
  end
end
