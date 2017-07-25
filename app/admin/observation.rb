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

end