# == Schema Information
#
# Table name: documents
#
#  id               :integer          not null, primary key
#  name             :string
#  document_type    :string
#  attachment       :string
#  attacheable_id   :integer
#  attacheable_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

FactoryGirl.define do
  factory :document do
    document_type 'Report'
    name 'Document'
    attachment { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'files', 'doc.pdf')) }
    association :attacheable, factory: :observation_1
  end
end
