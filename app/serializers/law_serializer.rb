# frozen_string_literal: true

# == Schema Information
#
# Table name: laws
#
#  id            :integer          not null, primary key
#  country_id    :integer
#  vpa_indicator :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class LawSerializer < ActiveModel::Serializer
  attributes :id, :vpa_indicator, :legal_reference, :legal_penalty

  belongs_to :country, serializer: CountrySerializer
end
