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
#  deleted_at       :datetime
#

class Photo < ApplicationRecord
  mount_base64_uploader :attachment, PhotoUploader

  belongs_to :user, inverse_of: :photos, optional: true # TODO: I think this is model is not used could be removed
  belongs_to :attacheable, polymorphic: true

  after_destroy :remove_attachment_id_directory

  acts_as_paranoid

  def remove_attachment_id_directory
    FileUtils.rm_rf(File.join('public', 'uploads', 'photo', 'attachment', self.id.to_s)) if self.attachment
  end
end
