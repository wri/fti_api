# frozen_string_literal: true

# == Schema Information
#
# Table name: contributors
#
#  id          :integer          not null, primary key
#  website     :string
#  logo        :string
#  priority    :integer
#  category    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  type        :string           default("Partner")
#  name        :string           not null
#  description :text
#

class Contributor < ApplicationRecord
  include Translatable
  mount_base64_uploader :logo, PartnerLogoUploader
  translates :name, :description, touch: true

  active_admin_translates :name do
    validates :name, presence: true
  end

  validates :priority, numericality: {only_integer: true, greater_than_or_equal_to: 0}, if: :priority?
  validates :name, presence: true
  validates :website, url: true
end
