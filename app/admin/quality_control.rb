ActiveAdmin.register QualityControl do
  extend BackRedirectable

  menu false

  actions :new, :create

  permit_params :reviewer_id, :reviewable_id, :reviewable_type, :passed, :comment

  controller do
    def new
      redirect_to reviewable_path, notice: I18n.t("active_admin.quality_control_page.reviewable_not_in_qc") and return unless reviewable.qc_in_progress?

      super
    end

    def create
      super do |format|
        redirect_to reviewable_path and return
      end
    end

    helper_method :reviewable_path
    def reviewable_path
      admin_observation_path(reviewable) if reviewable.is_a?(Observation)
    end

    helper_method :reviewable
    def reviewable
      @reviewable ||= if params[:reviewable_type] && params[:reviewable_id]
        params[:reviewable_type].constantize.find(params[:reviewable_id])
      else
        resource.reviewable
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.hidden_field :reviewer_id, value: current_user.id
    f.hidden_field :reviewable_id, value: params[:reviewable_id]
    f.hidden_field :reviewable_type, value: params[:reviewable_type]

    f.inputs do
      f.input :passed, as: :radio, collection: reviewable.qc_available_decisions, label: I18n.t("operator_documents.qc_form.decision")
      f.input :comment, as: :text
    end

    f.actions do
      f.action :submit, label: I18n.t("active_admin.submit")

      li class: "cancel" do
        link_to I18n.t("active_admin.cancel"), reviewable_path
      end
    end

    if params[:reviewable_type] == "Observation"
      render partial: "admin/observations/attributes_table", locals: {observation: reviewable}
    end
  end
end
