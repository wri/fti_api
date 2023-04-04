# frozen_string_literal: true

# == Schema Information
#
# Table name: about_page_entries
#
#  id         :integer          not null, primary key
#  position   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  code       :string
#  title      :string
#  body       :text
#

require "rails_helper"

RSpec.describe AboutPageEntry, type: :model do
  subject(:entry) { FactoryBot.build(:about_page_entry) }

  it "is valid with valid attributes" do
    expect(entry).to be_valid
  end

  it_should_behave_like "translatable", :about_page_entry, %i[title body]
end
