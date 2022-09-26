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

FactoryBot.define do
  factory :about_page_entry do
    sequence :position
    title { 'Title' }
    body { 'Body' }
    code { 'body' }
  end
end
