# frozen_string_literal: true

# == Schema Information
#
# Table name: uploaded_documents
#
#  id         :integer          not null, primary key
#  name       :string
#  author     :string
#  caption    :string
#  file       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :uploaded_document do
    name { "Document Name" }
    author { "Document Author" }
    caption { "Document Caption" }
    file { Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "files", "doc.pdf")) }
  end
end
