# frozen_string_literal: true

# == Schema Information
#
# Table name: severities
#
#  id             :integer          not null, primary key
#  level          :integer
#  severable_id   :integer          not null
#  severable_type :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class SeveritySerializer < ActiveModel::Serializer
  attributes :id, :level, :details

  has_many :comments, serializer: CommentSerializer
end
