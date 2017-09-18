# == Schema Information
#
# Table name: operators
#
#  id                                 :integer          not null, primary key
#  operator_type                      :string
#  country_id                         :integer
#  concession                         :string
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  is_active                          :boolean          default(TRUE)
#  logo                               :string
#  operator_id                        :string
#  percentage_valid_documents_all     :float
#  percentage_valid_documents_country :float
#  percentage_valid_documents_fmu     :float
#  certification                      :integer
#  score_absolute                     :float
#  score                              :integer
#  obs_per_visit                      :float
#  fa_id                              :string
#  address                            :string
#  website                            :string
#

FactoryGirl.define do
  factory :operator do
    name "Operator #{Faker::Lorem.sentence}"
    logo { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'files', 'image.png')) }

    after(:create) do |operator|
      operator.update(country: FactoryGirl.create(:country, name: "Country #{Faker::Lorem.sentence}",
                                                            iso: "C#{Faker::Lorem.sentence}"))
    end
  end
end
