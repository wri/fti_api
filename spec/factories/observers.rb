# == Schema Information
#
# Table name: observers
#
#  id                 :integer          not null, primary key
#  observer_type      :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  is_active          :boolean          default(TRUE), not null
#  address            :string
#  information_name   :string
#  information_email  :string
#  information_phone  :string
#  data_name          :string
#  data_email         :string
#  data_phone         :string
#  organization_type  :string
#  public_info        :boolean          default(FALSE), not null
#  responsible_qc2_id :integer
#  name               :string           not null
#  responsible_qc1_id :bigint
#

FactoryBot.define do
  factory :observer do
    sequence(:name) { |n| "Observer #{n}" }
    observer_type { "External" }
    sequence(:information_name) { |n| "Information name #{n}" }
    sequence(:information_email) { |n| "info_email#{n}@mail.com" }
    sequence(:information_phone) { |n| (n.to_s * 9).first(9) }
    sequence(:data_name) { |n| "Data name #{n}" }
    sequence(:data_email) { |n| "data_email#{n}@mail.com" }
    sequence(:data_phone) { |n| (n.to_s * 9).first(9) }
  end
end
