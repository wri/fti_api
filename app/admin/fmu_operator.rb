# frozen_string_literal: true

ActiveAdmin.register FmuOperator do
  extend BackRedirectable
  extend Versionable

  active_admin_paranoia

  menu false

  controller do
    def scoped_collection
      end_of_association_chain.includes([:operator, :fmu])
    end
  end

  actions :show, :edit, :index, :update, :new, :create

  permit_params :fmu_id, :operator_id, :current, :start_date, :end_date

  filter :operator, label: -> { I18n.t("activerecord.models.operator") }, as: :select,
    collection: -> { Operator.order(:name) }
  filter :fmu, label: -> { I18n.t("activerecord.models.fmu.one") }, as: :select,
    collection: -> { Fmu.by_name_asc }
  filter :current
  filter :start_date
  filter :end_date

  dependent_filters do
    {
      operator_id: {
        fmu_id: FmuOperator.where(current: true).distinct.pluck(:operator_id, :fmu_id)
      }
    }
  end

  csv do
    column :current
    column I18n.t("activerecord.models.fmu.one") do |fo|
      fo.fmu&.name
    end
    column I18n.t("activerecord.models.operator") do |fo|
      fo.operator&.name
    end
    column :start_date
    column :end_date
  end

  index do
    column :current
    column :fmu, sortable: "fmu_id" do |fo|
      if fo.fmu.present?
        link_to fo.fmu.name, admin_fmu_path(fo.fmu)
      elsif fo.fmu_id.present?
        fmu = Fmu.unscoped.find_by(id: fo.fmu_id)
        if fmu
          "#{link_to(fmu.name, admin_fmu_path(fmu))} (#{I18n.t("active_admin.shared.deleted")})".html_safe
        else
          "##{fo.fmu_id} (#{I18n.t("active_admin.shared.deleted")})"
        end
      end
    end
    column :operator, sortable: "operator_id" do |fo|
      if fo.operator.present?
        link_to fo.operator.name, admin_producer_path(fo.operator)
      elsif fo.operator_id.present?
        operator = Operator.unscoped.find_by(id: fo.operator_id)
        if operator
          "#{link_to(operator.name, admin_producer_path(operator))} (#{I18n.t("active_admin.shared.deleted")})".html_safe
        else
          "##{fo.operator_id} (#{I18n.t("active_admin.shared.deleted")})"
        end
      end
    end
    column :start_date
    column :end_date

    actions
  end

  form do |f|
    edit = !f.object.new_record?
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs do
      f.input :fmu, as: :select, input_html: {disabled: edit}
      f.input :operator, as: :select, input_html: {disabled: edit}
      f.input :start_date, as: :date_time_picker, picker_options: {timepicker: false, format: "Y-m-d"}
      f.input :end_date, as: :date_time_picker, picker_options: {timepicker: false, format: "Y-m-d"}
      f.input :current
    end

    f.actions
  end
end
