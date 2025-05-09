# == Schema Information
#
# Table name: newsletters
#
#  id                                :bigint           not null, primary key
#  date                              :date             not null
#  attachment                        :string           not null
#  image                             :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  title                             :string           not null
#  short_description                 :text             not null
#  title_translated_from             :string
#  short_description_translated_from :string
#
FactoryBot.define do
  factory :newsletter do
    title { "Newsletter title - Lelum polelum" }
    date { Time.zone.today }
    attachment { Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "files", "doc.pdf")) }
    short_description { "Here is some short description for the newsletter" }
  end
end
