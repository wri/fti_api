ActiveAdmin.register Observation do

  actions :all
  permit_params :name


  member_action :approve, method: :put do
    resource.update_attributes(validation_status: Observation.validation_statuses['Approved'])
    redirect_to resource_path, notice: 'Document approved'
  end

  member_action :reject, method: :put do
    resource.update_attributes(validation_status: Observation.validation_statuses['Rejected'])
    redirect_to resource_path, notice: 'Document rejected'
  end

  member_action :start_review, method: :put do
    resource.update_attributes(validation_status: Observation.validation_statuses['Under revision'])
    redirect_to resource_path, notice: 'Document under revision'
  end


  index do
    translation_status
    column :country
    column :fmu
    column 'Type', :observation_type
    column :operator
    column :observer
    column :publication_date
    column 'Active?', :is_active
    column 'Status', :validation_status
    column() { |observation| link_to 'Approve', approve_admin_observation_path(observation), method: :put}
    column() { |observation| link_to 'Reject', reject_admin_observation_path(observation), method: :put}
    column() { |observation| link_to 'Start Review', start_review_admin_observation_path(observation), method: :put}
  end

  filter :country
  filter :operator
  filter :updated_at


  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Country Details' do
      f.input :country
      f.input :fmu
      f.input :observer
      f.input :observation_type
      f.input :subcategory
      f.input :government
      f.input :operator
      f.input :publication_date, as: :date_picker
      f.input :pv
      f.input :lat
      f.input :lng
      f.input :validation_status
      f.input :is_active
    end
    f.inputs 'Translated fields' do
      f.translated_inputs switch_locale: false do |t|
        t.input :details
        t.input :evidence
        t.input :concern_opinion
        t.input :litigation_status
      end
    end
    f.actions
  end
end