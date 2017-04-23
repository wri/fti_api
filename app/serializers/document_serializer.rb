# frozen_string_literal: true

# == Schema Information
#
# Table name: documents
#
#  id               :integer          not null, primary key
#  name             :string
#  document_type    :string
#  attachment       :string
#  attacheable_id   :integer
#  attacheable_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :integer
#

class DocumentSerializer < ActiveModel::Serializer
  attributes :id, :name, :attachment, :document_type, :user_id

  belongs_to :attacheable
end
