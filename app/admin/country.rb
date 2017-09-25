ActiveAdmin.register Country do
  menu parent: 'Settings', priority: 6

  actions :show, :index

  config.order_clause

  scope :all
  scope :active

  filter :iso, as: :select
  filter :translations_name_contains, as: :select, label: 'Name',
         collection: Country.joins(:translations).pluck(:name)
  filter :region_iso, as: :select
  filter :region_name
  filter :is_active

  index do
    column :id, sortable: true
    column :iso, sortable: true
    column :name, sortable: 'country_translations.name'
    column :region_iso, sortable: true
    column :region_name, sortable: 'country_translations.region_name'
    column :is_active, sortable: true

    actions
  end

  # form do |f|
  #   f.semantic_errors *f.object.errors.keys
  #   f.inputs 'Fmu Details' do
  #     f.input :country,  input_html: { disabled: true }
  #     f.input :operator, input_html: { disabled: true }
  #
  #     f.translated_inputs switch_locale: false do |t|
  #       t.input :name
  #     end
  #
  #     f.actions
  #   end
  # end
end