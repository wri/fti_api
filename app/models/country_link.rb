# frozen_string_literal: true

# == Schema Information
#
# Table name: country_links
#
#  id              :integer          not null, primary key
#  url             :string
#  active          :boolean          default("true")
#  position        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  country_id      :integer
#  country_link_id :integer          not null
#  name            :string
#  description     :text
#
class CountryLink < ApplicationRecord
  belongs_to :country
  translates :name, :description, touch: true

  validates_presence_of :position, :url

  active_admin_translates :name do
    validates_presence_of :name
  end
  # rubocop:disable Style/BlockDelimiters
  active_admin_translates :description do; end
  # rubocop:enable Style/BlockDelimiters
end
