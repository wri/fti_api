# frozen_string_literal: true

# == Schema Information
#
# Table name: categorings
#
#  id                 :integer          not null, primary key
#  category_id        :integer          not null
#  categorizable_id   :integer
#  categorizable_type :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class Categoring < ApplicationRecord
  belongs_to :category
  belongs_to :categorizable, polymorphic: true
  belongs_to :annex_governance, foreign_key: :categorizable_id
  belongs_to :annex_operator,   foreign_key: :categorizable_id

  class << self
    def build(categorizable, category)
      new(categorizable: categorizable, category_id: category.id)
    end
  end
end
