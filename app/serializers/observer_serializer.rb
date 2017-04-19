# frozen_string_literal: true

# == Schema Information
#
# Table name: observers
#
#  id            :integer          not null, primary key
#  observer_type :string           not null
#  country_id    :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  is_active     :boolean          default(TRUE)
#  logo          :string
#

class ObserverSerializer < ActiveModel::Serializer
  attributes :id, :observer_type, :name, :organization, :is_active, :logo

  belongs_to :country, serializer: CountrySerializer
  has_many   :users,   serializer: UserSerializer
end
