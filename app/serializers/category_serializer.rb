# frozen_string_literal: true
# == Schema Information
#
# Table name: categories
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  category_type :integer
#

class CategorySerializer < ActiveModel::Serializer
  attributes :id, :name

  has_many :annex_governances
  has_many :annex_operators
end
