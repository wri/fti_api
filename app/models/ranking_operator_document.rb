# == Schema Information
#
# Table name: ranking_operator_documents
#
#  id          :integer          not null, primary key
#  date        :date             not null
#  current     :boolean          default("true"), not null
#  position    :integer          not null
#  operator_id :integer
#  country_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class RankingOperatorDocument < ApplicationRecord
  belongs_to :country
  belongs_to :operator

  validates_presence_of :date, :current, :position
end
