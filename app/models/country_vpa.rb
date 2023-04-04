# frozen_string_literal: true

# == Schema Information
#
# Table name: country_vpas
#
#  id          :integer          not null, primary key
#  url         :string
#  active      :boolean          default(TRUE)
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  country_id  :integer
#  name        :string
#  description :text
#
class CountryVpa < ApplicationRecord
  belongs_to :country
  translates :name, :description, touch: true

  validates_presence_of :position, :url

  active_admin_translates :name do
    validates_presence_of :name
  end
  # rubocop:disable Standard/BlockSingleLineBraces
  active_admin_translates :description do; end
  # rubocop:enable Standard/BlockSingleLineBraces
end
