# == Schema Information
#
# Table name: score_operator_documents
#
#  id          :integer          not null, primary key
#  date        :date             not null
#  current     :boolean          default("true"), not null
#  all         :float
#  country     :float
#  fmu         :float
#  operator_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe ScoreOperatorDocument, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
