# == Schema Information
#
# Table name: faqs
#
#  id         :integer          not null, primary key
#  position   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  image      :string
#  question   :string
#  answer     :text
#

require "rails_helper"

RSpec.describe Faq, type: :model do
  subject(:faq) { FactoryBot.build(:faq) }

  it "is valid with valid attributes" do
    expect(faq).to be_valid
  end

  it_should_behave_like "translatable", :faq, %i[question answer]
end
