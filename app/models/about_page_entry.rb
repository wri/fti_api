# frozen_string_literal: true

# == Schema Information
#
# Table name: about_page_entries
#
#  id         :integer          not null, primary key
#  position   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  code       :string
#  title      :string
#  body       :text
#
class AboutPageEntry < ApplicationRecord
  acts_as_list

  include Translatable
  translates :title, :body, touch: true

  active_admin_translates :title do
    validates :title, presence: true
  end

  active_admin_translates :body do
    validates :body, presence: true
  end
end
