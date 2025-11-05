# == Schema Information
#
# Table name: operator_document_annexes
#
#  id          :integer          not null, primary key
#  name        :string
#  start_date  :date
#  expire_date :date
#  deleted_at  :date
#  status      :integer
#  attachment  :string
#  uploaded_by :integer
#  user_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  public      :boolean          default(TRUE), not null
#

FactoryBot.define do
  factory :operator_document_annex do
    start_date { Date.yesterday }
    expire_date { Date.tomorrow }
    name { "annex name" }
    attachment { Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "files", "doc.pdf")) }

    transient do
      force_status { nil }
    end

    after(:build) do |random_operator_document_annex|
      if random_operator_document_annex.annex_document.nil? ||
          random_operator_document_annex.annex_documents.none?
        od = FactoryBot.create :operator_document_country
        AnnexDocument.create documentable_id: od.id,
          documentable_type: "OperatorDocument",
          operator_document_annex_id: random_operator_document_annex.id
      end
      random_operator_document_annex.user ||= FactoryBot.create :admin
    end

    after(:create) do |doc, evaluator|
      doc.update(status: evaluator.force_status) if evaluator.force_status
    end
  end
end
