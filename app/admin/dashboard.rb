# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu false

  page_action :change_language, method: :post do
    if current_user.update(locale: params[:locale])
      redirect_back fallback_location: admin_dashboard_path, notice: t("active_admin.dashboard_page.change_language.language_changed")
    else
      redirect_back fallback_location: admin_dashboard_path, notice: t("active_admin.dashboard_page.change_language.language_unchanged")
    end
  end

  page_action :deploy_portal, method: :post do
    authorize! :deploy_portal
    if system "rake deploy:portal"
      redirect_to admin_dashboard_path, notice: t("active_admin.dashboard_page.deploy_portal.deployed")
    else
      redirect_to admin_dashboard_path, alert: t("active_admin.dashboard_page.deploy_portal.error")
    end
  end

  page_action :deploy_ot, method: :post do
    authorize! :deploy_ot
    if system "rake deploy:tools"
      redirect_to admin_dashboard_path, notice: t("active_admin.dashboard_page.deploy_ot.deployed")
    else
      redirect_to admin_dashboard_path, alert: t("active_admin.dashboard_page.deploy_ot.error")
    end
  end

  page_action :hide_old_observations, method: :post do
    authorize! :hide_old_observations
    if system "rake observations:hide"
      redirect_to admin_dashboard_path, notice: t("active_admin.dashboard_page.hide_observations.hidden")
    else
      redirect_to admin_dashboard_path, notice: t("active_admin.dashboard_page.hide_observations.error")
    end
  end

  content title: proc { I18n.t("active_admin.dashboard") } do
    if current_user.user_permission.user_role == "admin"
      obs_count = Observation.where("publication_date < ? and hidden = false", Date.today - 5.year).count

      unless obs_count.zero?
        columns do
          button_to t("active_admin.dashboard_page.hide_observations.hide_observations"),
            "/admin/dashboard/hide_old_observations",
            method: :post,
            data:
            {
              disable_with: t("active_admin.dashboard_page.hide_observations.disable_with"),
              confirm: t("active_admin.dashboard_page.hide_observations.confirm")
            },
            class: "deploy-button"
        end
        panel t("active_admin.dashboard_page.old_observations.old_observations", count: obs_count) do
          table_for Observation.includes(:subcategory, :operator, country: :translations).to_be_hidden.order("observation_reports.publication_date desc").limit(20) do
            column("ID") { |obs| link_to obs.id, admin_observation_path(obs.id) }
            column(t("active_admin.dashboard_page.columns.publication_date")) { |obs| obs.observation_report&.publication_date }
            column(t("active_admin.dashboard_page.columns.country")) { |obs| obs.country }
            column(t("active_admin.dashboard_page.columns.subcategory")) { |obs| obs.subcategory }
            column(t("active_admin.dashboard_page.columns.operator")) { |obs| obs.operator }
            column(t("active_admin.dashboard_page.columns.date")) { |obs| obs.publication_date.strftime("%A, %d/%b/%Y") }
          end
        end
      end

      if Rails.env.staging? || Rails.env.development?
        columns do
          column do
            panel "Email tools" do
              div { link_to "Check email previews", "/rails/mailers" }
              div { link_to "Display all sent emails", letter_opener_web_path }
            end
          end
        end
      end

      columns do
        column do
          panel t("active_admin.dashboard_page.deploy_portal.portal") do
            button_to t("active_admin.dashboard_page.deploy_portal.deploy_portal"),
              "/admin/dashboard/deploy_portal",
              method: :post,
              data:
              {
                disable_with: t("active_admin.dashboard_page.deploy_portal.disable_with"),
                confirm: t("active_admin.dashboard_page.deploy_portal.confirm")
              },
              class: "deploy-button"
          end
        end

        column do
          panel t("active_admin.dashboard_page.deploy_ot.ot") do
            button_to t("active_admin.dashboard_page.deploy_ot.deploy_ot"),
              "/admin/dashboard/deploy_ot",
              method: :post,
              data:
              {
                disable_with: t("active_admin.dashboard_page.deploy_ot.disable_with"),
                confirm: t("active_admin.dashboard_page.deploy_ot.confirm")
              },
              class: "deploy-button"
          end
        end
      end
    end

    columns do
      column do
        panel t("active_admin.dashboard_page.new_producers.new_producers") do
          table_for Operator.inactive.includes(country: :translations).order("updated_at DESC").limit(20).each do
            column(t("active_admin.dashboard_page.columns.name")) { |o| link_to o.name, admin_producer_path(o.id) }
            column(t("active_admin.dashboard_page.columns.country")) { |o| o.country.present? ? o.country.name : t("active_admin.dashboard_page.new_producers.no_country") }
          end
        end
      end

      column do
        panel t("active_admin.dashboard_page.new_ims") do
          table_for Observer.inactive.includes(countries: :translations).order("updated_at DESC").limit(20).each do
            column(t("active_admin.dashboard_page.columns.name")) { |o| link_to o.name, admin_monitor_path(o.id) }
            column(t("active_admin.dashboard_page.columns.countries")) { |o| o.countries.each { |x| x.name }.join(", ") }
          end
        end
      end
    end

    columns do
      column do
        panel t("active_admin.dashboard_page.new_user_accounts") do
          table_for User.inactive.includes(:user_permission, country: :translations).order("updated_at DESC").limit(20).each do
            column(t("active_admin.dashboard_page.columns.name")) { |o| link_to o.name, admin_user_path(o.id) }
            column(t("active_admin.dashboard_page.columns.country")) { |o| o.country.name if o.country.present? }
            column(t("active_admin.dashboard_page.columns.role")) { |o| o.user_permission.user_role if o.user_permission.present? }
          end
        end
      end

      column do
        panel t("active_admin.dashboard_page.pending_observations", count: Observation.Created.count) do
          table_for Observation.Created.includes(:country, :subcategory, :operator).order("updated_at DESC").limit(20).each do
            column("ID") { |obs| link_to obs.id, admin_observation_path(obs.id) }
            column(t("active_admin.dashboard_page.columns.country")) { |obs| obs.country }
            column(t("active_admin.dashboard_page.columns.subcategory")) { |obs| obs.subcategory }
            column(t("active_admin.dashboard_page.columns.operator")) { |obs| obs.operator }
            column(t("active_admin.dashboard_page.columns.date")) { |obs| obs.publication_date.strftime("%A, %d/%b/%Y") }
          end
        end
      end
    end

    columns do
      column do
        panel t("active_admin.dashboard_page.pending_documents", count: OperatorDocument.doc_pending.count) do
          table_for OperatorDocument.doc_pending.includes(:operator, :required_operator_document).order("updated_at DESC").limit(20).each do
            column(t("active_admin.dashboard_page.columns.operator")) { |od| link_to od.operator.name, admin_producer_path(od.operator_id) }
            column(t("active_admin.dashboard_page.columns.name")) { |od| link_to od.required_operator_document.name, admin_operator_document_path(od.id) }
            column(t("active_admin.dashboard_page.columns.creation_date")) { |od| od.created_at.strftime("%A, %d/%b/%Y") }
          end
        end
      end
    end
    panel t("active_admin.dashboard_page.recently_updated_content") do
      table_for PaperTrail::Version.order(id: :desc).limit(20) do # Use PaperTrail::Version if this throws an error
        column(t("active_admin.dashboard_page.columns.item")) { |v| v.item }
        column(t("active_admin.dashboard_page.columns.type")) { |v| v.item_type.underscore.humanize }
        column(t("active_admin.dashboard_page.columns.modified_at")) { |v| v.created_at.to_s :long }
        column(t("active_admin.dashboard_page.columns.admin")) { |v|
          begin
            link_to User.find(v.whodunnit).email, [:admin, User.find(v.whodunnit)]
          rescue
            ""
          end
        }
      end
    end
  end
end
