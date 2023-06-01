# frozen_string_literal: true

# == Schema Information
#
# Table name: notification_groups
#
#  id         :integer          not null, primary key
#  days       :integer          not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class NotificationGroup < ApplicationRecord
  validates :days, :name, presence: true
end
