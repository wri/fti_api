# frozen_string_literal: true
# == Schema Information
#
# Table name: operators
#
#  id            :integer          not null, primary key
#  operator_type :string
#  country_id    :integer
#  concession    :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  is_active     :boolean          default(TRUE)
#  logo          :string
#  operator_id   :string
#

class OperatorSerializer < ActiveModel::Serializer
  attributes :id, :name, :operator_type, :concession, :is_active, :logo, :details

  belongs_to :country, serializer: CountrySerializer
  has_many :fmus, serializer: FmuSerializer
  has_many   :users,   serializer: UserSerializer
  has_many :observations, serializer: ObservationSerializer
end
