# frozen_string_literal: true

# == Schema Information
#
# Table name: api_keys
#
#  id           :integer          not null, primary key
#  access_token :string
#  expires_at   :datetime
#  user_id      :integer
#  is_active    :boolean          default(TRUE), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class APIKey < ApplicationRecord
  belongs_to :user

  include Activable

  def expired?
    DateTime.now >= expires_at || user.deactivated? || deactivated?
  end

  def self.ransackable_attributes(auth_object = nil)
    []
  end
end
