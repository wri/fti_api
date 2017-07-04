# frozen_string_literal: true
# == Schema Information
#
# Table name: severities
#
#  id             :integer          not null, primary key
#  level          :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  subcategory_id :integer
#

class SeveritySerializer < ActiveModel::Serializer
  attributes :id, :level, :details
end
