require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe 'Validations' do
    it { is_expected.to validate_presence_of(:email) }

    it { is_expected.to validate_uniqueness_of(:email) }
  end
end
