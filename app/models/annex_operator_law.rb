# frozen_string_literal: true

# == Schema Information
#
# Table name: annex_operator_laws
#
#  id                :integer          not null, primary key
#  annex_operator_id :integer
#  law_id            :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class AnnexOperatorLaw < ApplicationRecord
  belongs_to :law
  belongs_to :annex_operator
end
