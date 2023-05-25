# frozen_string_literal: true

# == Schema Information
#
# Table name: how_tos
#
#  id          :integer          not null, primary key
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  name        :string
#  description :text
#

class HowTo < ApplicationRecord
  translates :name, :description, touch: true
  active_admin_translates :name, :description
end
