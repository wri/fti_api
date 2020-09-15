# == Schema Information
#
# Table name: operators
#
#  id                :integer          not null, primary key
#  operator_type     :string
#  country_id        :integer
#  concession        :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_active         :boolean          default("true")
#  logo              :string
#  operator_id       :string
#  score_absolute    :float
#  score             :integer
#  obs_per_visit     :float
#  fa_id             :string
#  address           :string
#  website           :string
#  country_doc_rank  :integer
#  country_operators :integer
#  approved          :boolean          default("true"), not null
#  name              :string
#  details           :text
#

FactoryBot.define do
  factory :operator do
    country
    sequence(:name) { |n| "Operator #{n}" }
    logo { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'files', 'image.png')) }
    operator_type { Operator::TYPES.sample }
    is_active { true }
  end
end
