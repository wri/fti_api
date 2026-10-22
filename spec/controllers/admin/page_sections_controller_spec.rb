require "rails_helper"

RSpec.describe Admin::PageSectionsController, type: :controller do
  let(:admin) { create(:admin) }
  let(:page) { create(:page) }
  let!(:section) { create(:page_section, page: page, code: "partners") }

  render_views

  before { sign_in admin }

  describe "GET show" do
    subject { get :show, params: {page_id: page.id, id: section.id} }

    it { is_expected.to be_successful }
  end

  describe "GET new" do
    subject { get :new, params: {page_id: page.id} }

    it { is_expected.to be_successful }

    it "offers only known codes" do
      subject
      options = response.parsed_body.css("select#page_section_code option").pluck("value")
      expect(options).to eq([""] + PageSection::CODES)
    end
  end

  describe "GET edit" do
    subject { get :edit, params: {page_id: page.id, id: section.id} }

    it { is_expected.to be_successful }

    it "cancels back to the page" do
      subject
      expect(response.parsed_body.at_css("li.cancel a")["href"]).to eq(admin_page_path(page))
    end
  end

  describe "PATCH update" do
    subject do
      patch :update, params: {page_id: page.id, id: section.id, page_section: {code: "donors"}}
    end

    it "updates the section and returns to the page" do
      subject
      expect(section.reload.code).to eq("donors")
      expect(response).to redirect_to(admin_page_path(page))
    end
  end

  describe "POST create" do
    subject do
      post :create, params: {
        page_id: page.id,
        page_section: {code: "donors", translations_attributes: {"0" => {locale: "en", title: "Donors", body: ""}}}
      }
    end

    it "adds a section at the end and returns to the page" do
      expect { subject }.to change { page.sections.count }.by(1)
      expect(page.sections.last).to have_attributes(code: "donors", title: "Donors", position: 2)
      expect(response).to redirect_to(admin_page_path(page))
    end
  end

  describe "DELETE destroy" do
    subject { delete :destroy, params: {page_id: page.id, id: section.id} }

    it "removes the section and returns to the page" do
      expect { subject }.to change { page.sections.count }.by(-1)
      expect(response).to redirect_to(admin_page_path(page))
    end
  end
end
