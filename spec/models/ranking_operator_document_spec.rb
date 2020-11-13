# == Schema Information
#
# Table name: ranking_operator_documents
#
#  id          :integer          not null, primary key
#  date        :date             not null
#  current     :boolean          default("true"), not null
#  position    :integer          not null
#  operator_id :integer
#  country_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require 'rails_helper'

RSpec.describe RankingOperatorDocument, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
