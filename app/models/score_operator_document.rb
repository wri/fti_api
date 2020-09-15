# frozen_string_literal: true

# == Schema Information
#
# Table name: score_operator_documents
#
#  id          :integer          not null, primary key
#  date        :date             not null
#  active      :boolean          default("true"), not null
#  all         :float
#  country     :float
#  fmu         :float
#  operator_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class ScoreOperatorDocument < ApplicationRecord
  belongs_to :operator

  validates_presence_of :date
end
