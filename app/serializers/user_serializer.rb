# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                   :integer          not null, primary key
#  email                :string
#  password_digest      :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  nickname             :string
#  name                 :string
#  institution          :string
#  web_url              :string
#  is_active            :boolean          default(TRUE)
#  deactivated_at       :datetime
#  permissions_request  :integer
#  permissions_accepted :datetime
#  country_id           :integer
#

class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :nickname, :institution,
             :is_active, :deactivated_at, :web_url,
             :permissions_request, :permissions_accepted

  belongs_to :country,         serializer: CountrySerializer
  has_one    :user_permission, serializer: UserPermissionSerializer
  has_many   :comments,        serializer: CommentSerializer
end
