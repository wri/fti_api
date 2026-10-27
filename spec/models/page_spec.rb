require "rails_helper"

RSpec.describe Page, type: :model do
  subject(:page) { build(:page) }

  it "is valid with valid attributes" do
    expect(page).to be_valid
  end

  it_should_behave_like "translatable", :page, %i[title body]

  describe "sections" do
    let(:page) { create(:page) }

    it "returns sections ordered by position" do
      second = create(:page_section, page: page)
      first = create(:page_section, page: page)
      first.insert_at(1)

      expect(page.sections.reload).to eq([first, second])
    end

    it "destroys sections with the page" do
      create(:page_section, page: page)

      expect { page.destroy }.to change(PageSection, :count).by(-1)
    end
  end

  context "with a slug the portal depends on" do
    let(:page) { create(:page, slug: "about") }

    before { create(:page_section, page: page) }

    it "cannot change the slug" do
      expect(page.update(slug: "about-us")).to be(false)
      expect(page.errors[:slug]).to be_present
    end

    it "can change other attributes" do
      expect(page.update(title: "New title")).to be(true)
    end

    it "cannot be destroyed" do
      expect(page.destroy).to be(false)
      expect(page.errors[:base]).to be_present
      expect(page.sections.reload.count).to eq(1)
    end
  end

  context "with any other slug" do
    let(:page) { create(:page, slug: "some-page") }

    it "can change the slug and be destroyed" do
      expect(page.update(slug: "other-page")).to be(true)
      expect(page.destroy).to be_truthy
    end
  end
end
