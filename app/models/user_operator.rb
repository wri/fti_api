# frozen_string_literal: true

# == Schema Information
#
# Table name: user_operators
#
#  id          :integer          not null, primary key
#  operator_id :integer
#  user_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class UserOperator < ApplicationRecord
  belongs_to :operator
  belongs_to :user
end
