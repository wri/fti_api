# frozen_string_literal: true

# == Schema Information
#
# Table name: observers
#
#  id                :integer          not null, primary key
#  observer_type     :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_active         :boolean          default("true")
#  logo              :string
#  address           :string
#  information_name  :string
#  information_email :string
#  information_phone :string
#  data_name         :string
#  data_email        :string
#  data_phone        :string
#  organization_type :string
#  public_info       :boolean          default("false")
#  name              :string
#  organization      :string
#

class Holding < ApplicationRecord
  has_many :operators, dependent: :nullify

  validates_presence_of :name
end
