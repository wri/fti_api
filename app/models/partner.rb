# == Schema Information
#
# Table name: partners
#
#  id          :integer          not null, primary key
#  name        :string
#  website     :string
#  logo        :string
#  priority    :integer
#  category    :integer
#  description :text
#

class Partner < ApplicationRecord
  mount_base64_uploader :logo, PartnerLogoUploader

  validates :priority, numericality: {only_integer: true, greater_than_or_equal_to: 0 },  if: :priority?
  validates_presence_of :name



end
