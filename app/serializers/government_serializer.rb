# frozen_string_literal: true

class GovernmentSerializer < ActiveModel::Serializer
  attributes :id, :government_entity, :country_id, :details

  #has_many :observations
end
