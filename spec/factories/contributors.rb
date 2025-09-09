# == Schema Information
#
# Table name: contributors
#
#  id          :integer          not null, primary key
#  website     :string
#  logo        :string
#  priority    :integer
#  category    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  type        :string           default("Partner")
#  name        :string           not null
#  description :text
#

FactoryBot.define do
  factory :contributor do
    name { |n| "Contributor#{n}" }
    website { "http://website.com" }
    priority { rand(0..10) }
    logo { Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "files", "image.png")) }

    factory :partner, class: Partner do
      type { "Partner" }
    end

    factory :donor, class: Donor do
      type { "Donor" }
    end
  end
end
