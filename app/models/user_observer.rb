# frozen_string_literal: true

# == Schema Information
#
# Table name: user_observers
#
#  id          :integer          not null, primary key
#  observer_id :integer
#  user_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class UserObserver < ApplicationRecord
  belongs_to :observer
  belongs_to :user
end
