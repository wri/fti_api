ActiveAdmin.register Observation do

  actions :all
  permit_params :name

  collection_action :approve, method: :patch do

  end

  index do
    column :country
    column :fmu
    column :observation_type
    column :operator
    column :observer
    column :publication_date
    column :is_active
    column() { |observation| link_to 'Approve', action: :approve}
  end

#  filter :name
  filter :updated_at

end