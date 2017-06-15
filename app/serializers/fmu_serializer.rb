# == Schema Information
#
# Table name: fmus
#
#  id          :integer          not null, primary key
#  country_id  :integer
#  operator_id :integer
#  geojson     :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class FmuSerializer < ActiveModel::Serializer
  attributes :id, :name

  belongs_to :country, serializer: CountrySerializer
  belongs_to :operator, serializer: OperatorSerializer
end
