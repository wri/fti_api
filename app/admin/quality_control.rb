ActiveAdmin.register QualityControl do
  extend BackRedirectable

  menu false

  actions :new, :create

  permit_params :reviewer_id, :reviewable_id, :reviewable_type, :decision, :comment

  controller do
    def new
      super do
        set_title
        if resource.reviewable.respond_to?(:qc_in_progress?) && !resource.reviewable.qc_in_progress?
          redirect_to reviewable_path, notice: I18n.t("active_admin.quality_control_page.reviewable_not_in_qc") and return
        end
      end
    end

    def create
      super do |format|
        if resource.errors.empty?
          redirect_to params[:return_to] || reviewable_path, notice: I18n.t("active_admin.quality_control_page.performed_qc", decision: resource.decision) and return
        else
          resource.reviewable.reload
        end
      end
    end

    helper_method :reviewable_path
    def reviewable_path
      admin_observation_path(resource.reviewable) if resource.reviewable.is_a?(Observation)
    end

    def set_title
      @page_title = I18n.t("active_admin.quality_control_page.title", reviewable_type: resource.reviewable_type, reviewable_id: resource.reviewable_id)
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.hidden_field :reviewer_id, value: current_user.id
    f.hidden_field :reviewable_id, value: resource.reviewable_id
    f.hidden_field :reviewable_type, value: resource.reviewable_type
    f.hidden_field :rejectable_decisions, value: resource.reviewable.qc_rejectable_decisions.join(","), disabled: true

    f.inputs do
      f.input :decision, as: :radio, collection: resource.reviewable.qc_available_decisions, label: I18n.t("operator_documents.qc_form.decision")

      resource.reviewable.qc_available_decisions.each do |decision|
        next unless resource.reviewable.qc_decisions_hints[decision].present?

        li class: "input qc-decision-hint", style: "display: none;", "data-hint": decision do
          div class: "flash flash_warning" do
            resource.reviewable.qc_decisions_hints[decision]
          end
        end
      end

      f.input :comment, as: :text
    end

    f.actions do
      f.action :submit, label: I18n.t("active_admin.submit")

      li class: "cancel" do
        link_to I18n.t("active_admin.cancel"), reviewable_path
      end
    end

    render partial: "admin/#{resource.reviewable_type.pluralize.downcase}/attributes_table", locals: {observation: resource.reviewable}
  end
end
