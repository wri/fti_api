# frozen_string_literal: true

# == Schema Information
#
# Table name: api_keys
#
#  id           :integer          not null, primary key
#  access_token :string
#  expires_at   :datetime
#  user_id      :integer
#  is_active    :boolean          default(TRUE)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class APIKey < ApplicationRecord
  belongs_to :user

  include Activable

  def expired?
    DateTime.now >= self.expires_at || user.deactivated? || deactivated?
  end
end
