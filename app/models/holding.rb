# frozen_string_literal: true

# == Schema Information
#
# Table name: holdings
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Holding < ApplicationRecord
  has_many :operators, dependent: :nullify
  has_many :users, dependent: :nullify

  validates :name, presence: true
end
