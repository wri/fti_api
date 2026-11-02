FactoryBot.define do
  factory :page_section do
    page
    title { "Section title" }
    body { "<p>Section body</p>" }
  end
end
