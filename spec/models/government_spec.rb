# == Schema Information
#
# Table name: governments
#
#  id                :integer          not null, primary key
#  country_id        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_active         :boolean          default(TRUE), not null
#  government_entity :string
#  details           :text
#

require "rails_helper"

RSpec.describe Government, type: :model do
  subject(:government) { FactoryBot.build(:government) }

  it "is valid with valid attributes" do
    expect(government).to be_valid
  end

  it_should_behave_like "translatable", :government, %i[details]

  describe "Instance methods" do
    describe "#cache_key" do
      it "return the default value with the locale" do
        expect(government.cache_key).to match(/-#{Globalize.locale}\z/)
      end
    end
  end
end
