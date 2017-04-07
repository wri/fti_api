# == Schema Information
#
# Table name: photos
#
#  id               :integer          not null, primary key
#  name             :string
#  attachment       :string
#  attacheable_id   :integer
#  attacheable_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

RSpec.describe Photo, type: :model do
  before :each do
    @photo = create(:photo)
  end

  it 'Count on law' do
    expect(Photo.count).to eq(1)
    expect(@photo.attacheable.illegality).to eq('Illegality one')
  end
end
