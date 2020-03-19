# == Schema Information
#
# Table name: operator_document_annexes
#
#  id                   :integer          not null, primary key
#  operator_document_id :integer
#  name                 :string
#  start_date           :date
#  expire_date          :date
#  deleted_at           :date
#  status               :integer
#  attachment           :string
#  uploaded_by          :integer
#  user_id              :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  public               :boolean          default("true"), not null
#

FactoryBot.define do
  factory :operator_document_annex do
    start_date { Date.yesterday }
    expire_date { Date.tomorrow }

    after(:build) do |random_operator_document_annex|
      random_operator_document_annex.operator_document ||=
        FactoryBot.create :operator_document
      random_operator_document_annex.user ||=
        FactoryBot.create :admin
    end
  end
end
