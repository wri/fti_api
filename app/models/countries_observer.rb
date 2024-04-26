# frozen_string_literal: true

# == Schema Information
#
# Table name: countries_observers
#
#  country_id  :integer          not null
#  observer_id :integer          not null
#
class CountriesObserver < ApplicationRecord
  belongs_to :country
  belongs_to :observer
end
