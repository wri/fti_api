require "rails_helper"

ActiveAdmin.application.namespaces[:admin].resources.each do |resource|
  # resource_name will be empty for custom pages not backed by models
  resource_name = resource.resource_name.instance_variable_get(:@klass)&.name&.underscore

  describe resource.controller, type: :controller do
    let(:admin) { create(:admin) }
    let!(:model) { create(resource_name) if FactoryBot.factories.registered?(resource_name) }

    render_views

    before(:each) do
      sign_in(admin)
    end

    if resource.is_a?(ActiveAdmin::Page) || resource.defined_actions.include?(:index)
      describe "GET index" do
        subject { get :index }

        it { is_expected.to be_successful }

        it "does not include empty translations" do
          subject
          expect(response.body).not_to include("translation missing")
        end

        if resource_name
          it "responds to csv" do
            get :index, format: :csv
            expect(response.body).to be_present # otherwise it does not invoke csv code
            expect(response.content_type).to include("text/csv")
            expect(response.body).not_to include("translation missing")
          end
        end
      end
    end

    if FactoryBot.factories.registered?(resource_name)
      if resource.is_a?(ActiveAdmin::Page) || resource.defined_actions.include?(:show)
        describe "GET show" do
          subject { get :show, params: {id: model.id} }

          it { is_expected.to be_successful }

          it "does not include empty translations" do
            subject
            expect(response.body).not_to include("translation missing")
          end
        end
      end

      if resource.is_a?(ActiveAdmin::Page) || resource.defined_actions.include?(:edit)
        describe "GET edit" do
          subject { get :edit, params: {id: model.id} }

          it { is_expected.to be_successful }

          it "does not include empty translations" do
            subject
            expect(response.body).not_to include("translation missing")
          end
        end
      end

      if resource.is_a?(ActiveAdmin::Page) || resource.defined_actions.include?(:new)
        describe "GET new" do
          subject { get :new }

          it { is_expected.to be_successful }

          it "does not include empty translations" do
            subject
            expect(response.body).not_to include("translation missing")
          end
        end
      end
    end
  end
end
