# == Schema Information
#
# Table name: contacts
#
#  id         :integer          not null, primary key
#  name       :string
#  email      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe 'Validations' do
  end
end
