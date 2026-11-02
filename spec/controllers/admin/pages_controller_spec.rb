require "rails_helper"

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::PagesController, type: :controller do
  let(:admin) { create(:admin) }

  render_views

  before { sign_in admin }

  describe "GET show" do
    let(:page) { create(:page) }
    let!(:section) { create(:page_section, page: page, title: "Our partners", code: "partners") }

    subject { get :show, params: {id: page.id} }

    it "lists the sections" do
      subject
      expect(response).to be_successful
      expect(response.body).to include("Our partners")
      expect(response.body).to include(edit_admin_page_page_section_path(page, section))
      expect(response.body).to include(new_admin_page_page_section_path(page))
    end
  end

  describe "DELETE destroy" do
    let!(:page) { create(:page, slug: "about") }

    subject { delete :destroy, params: {id: page.id} }

    it "does not delete a page the portal links to" do
      expect { subject }.not_to change(Page, :count)
      expect(flash[:error] || flash[:alert]).to be_present
    end
  end
end
