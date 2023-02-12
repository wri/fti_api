# frozen_string_literal: true

ActiveAdmin.register FmuOperator do
  extend BackRedirectable
  extend Versionable

  active_admin_paranoia

  menu false

  controller do
    def scoped_collection
      end_of_association_chain.includes([:operator, [fmu: :translations]])
    end
  end

  actions :show, :edit, :index, :update, :new, :create

  permit_params :fmu_id, :operator_id, :current, :start_date, :end_date

  filter :operator, label: I18n.t('activerecord.models.operator'), as: :select,
                    collection: -> { Operator.order(:name) }
  filter :fmu, label: I18n.t('activerecord.models.fmu.one'), as: :select,
               collection: -> { Fmu.with_translations(I18n.locale).order('fmu_translations.name') }
  filter :current
  filter :start_date
  filter :end_date

  csv do
    column :current
    column I18n.t('activerecord.models.fmu.one') do |fo|
      fo.fmu&.name
    end
    column I18n.t('activerecord.models.operator') do |fo|
      fo.operator&.name
    end
    column :start_date
    column :end_date
  end

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
