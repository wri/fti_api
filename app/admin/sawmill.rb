# frozen_string_literal: true

ActiveAdmin.register Sawmill do
  # menu parent: 'Operators', priority: 2
  menu false

  config.order_clause

  actions :all
  permit_params :operator_id, :name, :lat, :lng, :is_active

  member_action :activate, method: :put do
    resource.update_attributes(is_active: true)
    redirect_to collection_path, notice: 'Operator activated'
  end

  index do
    column 'Active?', :is_active
    column :name
    column :operator, sortable: 'operator_translations.name'
    column 'Latitude', :lat
    column 'Longitude', :lng
    column('Actions') do |sawmill|
      unless sawmill.is_active
        a 'Activate', href: activate_admin_sawmill_path(sawmill),
                      'data-method': :put, 'data-confirm': "Are you sure you want to ACTIVATE the sawmill #{sawmill.name}?"
      end
    end

    actions
  end

  scope :all, default: true
  scope :active
  scope :inactive

  filter :operator_translations_name_contains,
         as: :select, label: 'Operator',
         collection: Operator.joins(:sawmills).with_translations(I18n.locale)
                         .order('operator_translations.name').pluck('operator_translations.name')
  filter :name



  form do |f|
    edit = f.object.new_record? ? false : true
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Sawmill Details' do
      f.input :operator, input_html: { disabled: edit }
      f.input :name
      f.input :lat, label: 'Latitude'
      f.input :lng, label: 'Longitude'
      f.input :is_active
    end
    f.actions
  end

  csv do
    column 'operator' do |s|
      s.operator&.name
    end
    column :name
    column :lat
    column :lng
    column :is_active
    column :created_at
    column :updated_at
  end

  show do
    attributes_table do
      row :operator
      row :name
      row :lat
      row :lng
      row :is_active
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end



  controller do
    def scoped_collection
      end_of_association_chain.includes([operator: :translations])
    end
  end
end
