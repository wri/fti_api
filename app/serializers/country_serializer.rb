# frozen_string_literal: true

# == Schema Information
#
# Table name: countries
#
#  id               :integer          not null, primary key
#  iso              :string
#  region_iso       :string
#  country_centroid :jsonb
#  region_centroid  :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  is_active        :boolean          default(FALSE), not null
#


class CountrySerializer < ActiveModel::Serializer
  attributes :id, :iso, :region_iso, :country_centroid, :region_centroid, :is_active, :name, :region_name

  has_many :fmus, serializer: FmuSerializer
end
