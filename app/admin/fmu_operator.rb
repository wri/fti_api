# frozen_string_literal: true

ActiveAdmin.register FmuOperator do
  # menu parent: 'Settings', priority: 5
  menu false

  actions :show, :edit, :index, :update, :new, :create

  permit_params :fmu_id, :operator_id, :current, :start_date, :end_date

  index do
    column :current
    column :fmu
    column :operator
    column :start_date
    column :end_date

    actions
  end

  form do |f|
    edit = f.object.new_record? ? false : true
    f.semantic_errors *f.object.errors.keys

    f.inputs do
      f.input :fmu, as: :select, input_html: { disabled: edit }
      f.input :operator, as: :select, input_html: { disabled: edit }
      f.input :start_date, as: :date_time_picker, picker_options: { timepicker: false }
      f.input :end_date, as: :date_time_picker, picker_options: { timepicker: false }
      f.input :current
    end

    f.actions
  end
end
