require 'rails_helper'

ActiveAdmin.application.namespaces[:admin].resources.each do |resource|
  resource_name = resource.resource_name.singular

  describe resource.controller, type: :controller do
    let(:admin) { create(:admin) }
    let!(:model) { create(resource_name) if FactoryBot.factories.registered?(resource_name) }

    render_views

    before(:each) do
      sign_in(admin)
    end

    if resource.is_a?(ActiveAdmin::Page) || resource.defined_actions.include?(:index)
      describe "GET index" do
        it "returns http success" do
          get :index

          expect(response.status).to eq(200)
          expect(response).to have_http_status(:success)
        end
      end
    end

    if resource.is_a?(ActiveAdmin::Page) || resource.defined_actions.include?(:show)
      describe "GET index" do
        it "returns http success" do
          get :index

          expect(response.status).to eq(200)
          expect(response).to be_success
        end
      end
    end
  end
end
