# == Schema Information
#
# Table name: newsletters
#
#  id                :bigint           not null, primary key
#  date              :date             not null
#  attachment        :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  title             :string           not null
#  short_description :text             not null
#
require "rails_helper"

RSpec.describe Newsletter, type: :model do
  subject(:newsletter) { build(:newsletter) }

  it_should_behave_like "translatable", :newsletter, %i[title short_description]

  describe "Validations" do
    it "is valid with valid attributes" do
      expect(newsletter).to be_valid
    end

    it "validates presence of date" do
      subject.date = nil
      expect(subject).not_to be_valid
      expect(subject.errors.messages[:date]).to include("can't be blank")
    end

    it "validates presence of attachment" do
      subject.remove_attachment!
      expect(subject).not_to be_valid
      expect(subject.errors.messages[:attachment]).to include("can't be blank")
    end
  end
end
