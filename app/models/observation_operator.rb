# frozen_string_literal: true

# == Schema Information
#
# Table name: observation_operators
#
#  id             :integer          not null, primary key
#  observation_id :integer
#  operator_id    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class ObservationOperator < ApplicationRecord
  belongs_to :operator
  belongs_to :observation
end
