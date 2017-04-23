# frozen_string_literal: true

# == Schema Information
#
# Table name: photos
#
#  id               :integer          not null, primary key
#  name             :string
#  attachment       :string
#  attacheable_id   :integer
#  attacheable_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :integer
#

class PhotoSerializer < ActiveModel::Serializer
  attributes :id, :name, :attachment, :user_id

  belongs_to :attacheable
end
