# frozen_string_literal: true

# == Schema Information
#
# Table name: annex_governances
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AnnexGovernanceSerializer < ActiveModel::Serializer
  attributes :id, :governance_pillar, :governance_problem, :details

  has_many :severities, serializer: SeveritySerializer
  has_many :categories, serializer: CategorySerializer
  has_many :comments,   serializer: CommentSerializer
end
