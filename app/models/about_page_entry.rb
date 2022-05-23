# frozen_string_literal: true

# == Schema Information
#
# Table name: about_page_entries
#
#  id         :integer          not null, primary key
#  position   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class AboutPageEntry < ApplicationRecord
  include Translatable
  translates :title, :body, touch: true

  validates_uniqueness_of :position
  validates_presence_of :position

  active_admin_translates :title do
   validates_presence_of :title
  end

  active_admin_translates :body do
    validates_presence_of :body
  end
end
