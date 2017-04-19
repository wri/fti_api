# frozen_string_literal: true

# == Schema Information
#
# Table name: governments
#
#  id         :integer          not null, primary key
#  country_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#


class GovernmentSerializer < ActiveModel::Serializer
  attributes :id, :government_entity, :details

  belongs_to :country, serializer: CountrySerializer
end
