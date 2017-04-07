# frozen_string_literal: true

# == Schema Information
#
# Table name: user_permissions
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  user_role   :integer          default("user"), not null
#  permissions :jsonb
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#


class UserPermissionSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :user_role, :permissions
end
