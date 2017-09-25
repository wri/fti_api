ActiveAdmin.register Fmu do
  menu parent: 'Settings', priority: 5

  actions :show, :edit, :index, :update

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes([:translations, [country: :translations],
                                         [operator: :translations]])
    end
  end

  scope :all, default: true
  scope 'Free', :filter_by_free

  permit_params :id, translations_attributes: [:id, :locale, :name]

  filter :id, as: :select
  filter :translations_name_contains, as: :select, label: 'Name',
         collection: Fmu.joins(:translations).pluck(:name)
  filter :country
  filter :operator

  index do
    column :id, sortable: true
    column :name, sortable: 'fmu_translations.name'
    column :country, sortable: 'country_translations.name'
    column :operator, sortable: 'operator_translations.name'

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Fmu Details' do
      f.input :country,  input_html: { disabled: true }
      f.input :operator, input_html: { disabled: true }
    end

    f.inputs 'Translated fields' do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
      end
    end

    f.actions
  end
end