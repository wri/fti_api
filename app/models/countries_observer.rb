# frozen_string_literal: true

class CountriesObserver < ApplicationRecord
  belongs_to :country
  belongs_to :observer
end
