require "rails_helper"

RSpec.describe PageSection, type: :model do
  subject(:section) { build(:page_section) }

  it "is valid with valid attributes" do
    expect(section).to be_valid
  end

  it_should_behave_like "translatable", :page_section, %i[title body]

  describe "code" do
    it "accepts known codes" do
      PageSection::CODES.each do |code|
        section.code = code
        expect(section).to be_valid
      end
    end

    it "rejects unknown codes" do
      section.code = "partner"
      expect(section).not_to be_valid
    end

    it "stores a blank code as nil" do
      section.code = ""
      expect(section.code).to be_nil
    end
  end

  # translation validations run for the nested attributes the admin form submits
  describe "title and body" do
    [{title: "Titre", body: ""}, {title: "", body: "<p>Corps</p>"}].each do |fr|
      context "with blank #{fr.key("").inspect}" do
        subject(:section) do
          PageSection.new(page: build(:page), code: code, translations_attributes: [
            {locale: "en", title: "Title", body: "<p>Body</p>"},
            fr.merge(locale: "fr")
          ])
        end

        context "without a code" do
          let(:code) { nil }

          it { is_expected.not_to be_valid }
        end

        context "with a code" do
          let(:code) { "related_pages" }

          it { is_expected.to be_valid }
        end
      end
    end
  end

  it "keeps positions per page" do
    page = create(:page)
    other_page = create(:page)
    create(:page_section, page: page)

    expect(create(:page_section, page: other_page).position).to eq(1)
    expect(create(:page_section, page: page).position).to eq(2)
  end

  it "touches the page" do
    section = create(:page_section)
    page = section.page

    expect { section.update!(title: "Changed") }.to change { page.reload.updated_at }
  end
end
