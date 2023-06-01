# frozen_string_literal: true

# == Schema Information
#
# Table name: faqs
#
#  id         :integer          not null, primary key
#  position   :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  image      :string
#  question   :string
#  answer     :text
#

class Faq < ApplicationRecord
  include Translatable
  translates :question, :answer, touch: true

  validates :position, presence: true, uniqueness: true

  active_admin_translates :question do
    validates :question, presence: true
  end

  active_admin_translates :answer do
    validates :answer, presence: true
  end
end
