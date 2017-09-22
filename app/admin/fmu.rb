ActiveAdmin.register Fmu do
  menu parent: 'Settings', priority: 4

  actions :show, :edit, :index

  config.order_clause

  # permit_params :id, :subcategory_id, :infraction, :sanctions, :min_fine, :max_fine, :penal_servitude,
  #               :other_penalties, :flegt

  index do
    column :id, sortable: true
    column :country, sortable: true
    column :operator, sortable: true
    column :name, sortable: true

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Fmu Details' do
      f.input :country,  input_html: { disabled: true }
      f.input :operator, input_html: { disabled: true }

      f.translated_inputs switch_locale: false do |t|
        t.input :name
      end

      f.actions
    end
  end
end