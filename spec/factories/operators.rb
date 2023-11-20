# == Schema Information
#
# Table name: operators
#
#  id                :integer          not null, primary key
#  operator_type     :string
#  country_id        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_active         :boolean          default(TRUE), not null
#  logo              :string
#  operator_id       :string
#  fa_id             :string
#  address           :string
#  website           :string
#  approved          :boolean          default(TRUE), not null
#  holding_id        :integer
#  country_doc_rank  :integer
#  country_operators :integer
#  name              :string
#  details           :string
#  slug              :string
#

FactoryBot.define do
  factory :operator do
    country
    sequence(:name) { |n| "Operator #{n}" }
    logo { Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "files", "image.png")) }
    operator_type { "Logging company" }
    is_active { true }

    trait :with_sawmills do
      after(:create) do |op|
        create_list(:sawmill, 2, operator: op)
      end
    end

    trait :with_documents do
      after(:create) do |op|
        op.update!(fa_id: "FA_UUID") if op.fa_id.blank?
        # create one country document
        create(:operator_document_country, operator: op)
        create(:operator_document_fmu, operator: op, force_status: "doc_valid")
        create(:operator_document_fmu, operator: op, force_status: "doc_invalid")
      end
    end
  end
end
