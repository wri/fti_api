# frozen_string_literal: true

# == Schema Information
#
# Table name: annex_operators
#
#  id         :integer          not null, primary key
#  country_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class AnnexOperatorSerializer < ActiveModel::Serializer
  attributes :id, :illegality, :details

  belongs_to :country,    serializer: CountrySerializer
  has_many   :severities, serializer: SeveritySerializer
  has_many   :categories, serializer: CategorySerializer
  has_many   :comments,   serializer: CommentSerializer
  has_many   :laws,       serializer: LawSerializer
end
