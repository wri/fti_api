# frozen_string_literal: true

class CustomAdminHeader < ActiveAdmin::Views::Header
  include Rails.application.routes.url_helpers

  def build(namespace, menu) # rubocop:disable Metrics/AbcSize
    div class: "c-nav" do
      div class: "logo" do
        div do
          image_tag(image_url("logo.svg"))
        end
        div class: "env" do
          Rails.env.humanize
        end
      end
      div class: "list" do
        ul do
          li do
            text_node content_tag "a", t("active_admin.menu.dashboard.dashboard")
            ul do
              li { link_to t("active_admin.menu.dashboard.start_page"), admin_dashboard_path }
              li { link_to t("active_admin.menu.dashboard.producer_documents_dashboard"), admin_producer_documents_dashboards_path }
              li { link_to t("active_admin.menu.dashboard.observation_reports_dashboard"), admin_observation_reports_dashboards_path }
              li { link_to t("active_admin.menu.dashboard.observations_dashboard"), admin_observations_dashboards_path }
            end
          end
        end

        ul do
          li do
            text_node content_tag "a", t("active_admin.menu.independent_monitoring.independent_monitoring")
            ul do
              li { link_to t("active_admin.menu.independent_monitoring.monitors"), admin_monitors_path }
              li { link_to t("active_admin.menu.independent_monitoring.observations"), admin_observations_path }
              li { link_to t("active_admin.menu.independent_monitoring.reports"), admin_observation_reports_path }
              li { link_to t("active_admin.menu.independent_monitoring.evidence"), admin_evidences_path }
              li do
                text_node content_tag "a", t("active_admin.menu.independent_monitoring.settings.settings"), class: "-with-children"
                ul do
                  li { link_to t("active_admin.menu.independent_monitoring.settings.categories"), admin_categories_path }
                  li { link_to t("active_admin.menu.independent_monitoring.settings.subcategories"), admin_subcategories_path }
                  li { link_to t("active_admin.menu.independent_monitoring.settings.severities"), admin_severities_path }
                  li { link_to t("active_admin.menu.independent_monitoring.settings.laws"), admin_laws_path }
                  li { link_to t("active_admin.menu.independent_monitoring.settings.government_entities"), admin_governments_path }
                  li { link_to t("active_admin.menu.independent_monitoring.settings.species"), admin_species_index_path }
                end
              end
            end
          end
        end

        ul do
          li do
            text_node content_tag "a", t("active_admin.menu.private_sector.private_sector")
            ul do
              li { link_to t("active_admin.menu.private_sector.holdings"), admin_holdings_path }
              li { link_to t("active_admin.menu.private_sector.producers"), admin_producers_path }
              li { link_to t("active_admin.menu.private_sector.sawmills"), admin_sawmills_path }
              li { link_to t("active_admin.menu.private_sector.document_categories"), admin_required_operator_document_groups_path }
              li { link_to t("active_admin.menu.private_sector.required_documents"), admin_required_operator_documents_path }
              li do
                text_node content_tag "a", t("active_admin.menu.private_sector.producer_documents.producer_documents"), class: "-with-children"
                ul do
                  li { link_to t("active_admin.menu.private_sector.producer_documents.producer_documents"), admin_operator_documents_path }
                  li { link_to t("active_admin.menu.private_sector.producer_documents.producer_documents_history"), admin_operator_document_histories_path }
                end
              end
              li { link_to t("active_admin.menu.private_sector.annexes"), admin_operator_document_annexes_path }
              li do
                text_node content_tag "a", t("active_admin.menu.private_sector.settings.settings"), class: "-with-children"
                ul do
                  li { link_to t("active_admin.menu.private_sector.settings.countries"), admin_countries_path }
                  li { link_to t("active_admin.menu.private_sector.settings.protected_areas"), admin_protected_areas_path }
                  li { link_to t("active_admin.menu.private_sector.settings.fmus"), admin_fmus_path }
                  li { link_to t("active_admin.menu.private_sector.settings.fmu_allocations"), admin_fmu_operators_path }
                end
              end
            end
          end
        end

        ul do
          li do
            text_node content_tag "a", t("active_admin.menu.government_sector.government_sector")
            ul do
              li { link_to t("active_admin.menu.government_sector.required_document_group"), admin_required_gov_document_groups_path }
              li { link_to t("active_admin.menu.government_sector.required_documents"), admin_required_gov_documents_path }
              li { link_to t("active_admin.menu.government_sector.documents"), admin_gov_documents_path }
              li { link_to t("active_admin.menu.government_sector.links"), admin_country_links_path }
              li { link_to t("active_admin.menu.government_sector.vpas"), admin_country_vpas_path }
            end
          end
        end

        ul do
          li do
            text_node content_tag "a", t("active_admin.menu.static_content.static_content")
            ul do
              li { link_to t("active_admin.menu.static_content.pages"), admin_pages_path }
              li { link_to t("active_admin.menu.static_content.partners"), admin_partners_path }
              li { link_to t("active_admin.menu.static_content.donors"), admin_donors_path }
              li { link_to t("active_admin.menu.static_content.about_page"), admin_about_page_entries_path }
              li do
                text_node content_tag "a", t("active_admin.menu.static_content.help_page.help_page"), class: "-with-children"
                ul do
                  li { link_to t("active_admin.menu.static_content.help_page.faqs"), admin_faqs_path }
                  li { link_to t("active_admin.menu.static_content.help_page.how_tos"), admin_how_tos_path }
                  li { link_to t("active_admin.menu.static_content.help_page.tools"), admin_tools_path }
                  li { link_to t("active_admin.menu.static_content.help_page.tutorials"), admin_tutorials_path }
                  li { link_to t("active_admin.menu.static_content.help_page.uploaded_documents"), admin_uploaded_documents_path }
                end
              end
            end
          end
        end

        ul do
          li do
            text_node content_tag "a", t("active_admin.menu.user_management.user_management")
            ul do
              li { link_to t("active_admin.menu.user_management.users"), admin_users_path }
              li { link_to t("active_admin.menu.user_management.access_control"), admin_access_control_path }
              li { link_to t("active_admin.menu.user_management.comments"), admin_comments_path }
              li do
                text_node content_tag "a", t("active_admin.menu.user_management.notifications.notifications"), class: "-with-children"
                ul do
                  li { link_to t("active_admin.menu.user_management.notifications.notifications"), admin_notification_groups_path }
                  li { link_to t("active_admin.menu.user_management.notifications.notification_groups"), admin_notifications_path }
                end
              end
            end
          end
        end
      end
    end

    div class: "c-nav" do
      div class: "list" do
        ul do
          li do
            text_node content_tag "a", t("active_admin.menu.language.language")
            ul do
              li { link_to t("active_admin.menu.language.english"), admin_dashboard_change_language_path(locale: :en), method: :post }
              li { link_to t("active_admin.menu.language.french"), admin_dashboard_change_language_path(locale: :fr), method: :post }
            end
          end
        end
        ul class: "user" do
          li { link_to @arbre_context.assigns[:current_user].email, admin_user_path(@arbre_context.assigns[:current_user].id) }
        end
        ul class: "logout" do
          li { link_to t("active_admin.menu.logout"), destroy_user_session_path }
        end
      end
    end
    # workaround for translating jump to page string
    div id: "jump-to-page", style: "display: none;", "data-value": I18n.t("active_admin.js.jump_to_page")
  end
end
