ActiveAdmin.register FmuOperator do
  menu parent: 'Settings', priority: 5

  actions :show, :edit, :index, :update, :new, :create

  permit_params :fmu_id, :operator_id, :current, :start_date, :end_date
end
