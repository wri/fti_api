# == Schema Information
#
# Table name: newsletters
#
#  id                :bigint           not null, primary key
#  date              :date             not null
#  attachment        :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  title             :string           not null
#  short_description :text             not null
#
class Newsletter < ApplicationRecord
  include Translatable
  translates :title, :short_description, touch: true

  mount_base64_uploader :attachment, NewsletterUploader
  mount_base64_uploader :image, NewsletterImageUploader

  validates :date, presence: true
  validates :attachment, presence: true

  active_admin_translates :title, :short_description do
    validates :title, presence: true
    validates :short_description, presence: true
  end
end
