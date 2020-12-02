# frozen_string_literal: true

class CustomAdminHeader < ActiveAdmin::Views::Header
  include Rails.application.routes.url_helpers

  def build(namespace, menu)
    div class: 'c-nav' do
      div class: 'logo' do
        div do
          image_tag(image_url("logo.svg"))
        end
        div class: 'env' do
          Rails.env.humanize
        end
      end
      div class: 'list' do
        ul do
          li do
            text_node content_tag 'a', 'Dashboard'
            ul do
              li { link_to 'Start Page', admin_dashboard_path }
              li { link_to 'Global Scores', admin_global_scores_path }

            end
          end
        end

        ul do
          li do
            text_node content_tag 'a', 'Independent Monitoring'
            ul do
              li { link_to 'Monitors',         admin_monitors_path }
              li { link_to 'Observations',     admin_observations_path }
              li { link_to 'Reports',          admin_observation_reports_path }
              li { link_to 'Evidence',         admin_evidences_path }
              li do
                text_node content_tag 'a', 'Settings', class: '-with-children'
                ul do
                  li { link_to 'Categories',             admin_categories_path }
                  li { link_to 'Subcategories',          admin_subcategories_path }
                  li { link_to 'Severities',             admin_severities_path }
                  li { link_to 'Laws',                   admin_laws_path }
                  li { link_to 'Government Entities',    admin_governments_path }
                  li { link_to 'Species',                admin_species_index_path }
                end
              end
            end
          end
        end

        ul do
          li do
            text_node content_tag 'a', 'Private Sector'
            ul do
              li { link_to 'Holdings',             admin_holdings_path }
              li { link_to 'Producers',            admin_producers_path }
              li { link_to 'Sawmills',             admin_sawmills_path }
              li { link_to 'Document Categories',  admin_required_operator_document_groups_path }
              li { link_to 'Required Documents',   admin_required_operator_documents_path }
              li do
                text_node content_tag 'a', 'Producer Documents', class: '-with-children'
                ul do
                  li { link_to 'Producer Documents',     admin_operator_documents_path }
                  li { link_to 'Old Producer Documents', admin_operator_document_histories_path }
                end
              end
              li { link_to 'Annexes',              admin_operator_document_annexes_path }
              li do
                text_node content_tag 'a', 'Settings', class: '-with-children'
                ul do
                  li { link_to 'Countries',            admin_countries_path }
                  li { link_to 'Fmus',                 admin_fmus_path }
                  li { link_to 'Fmu allocations',      admin_fmu_operators_path }
                end
              end
            end
          end
        end

        ul do
          li do
            text_node content_tag 'a', 'Government Sector'
            ul do
              li { link_to 'Required Document Group',  admin_required_gov_document_groups_path }
              li { link_to 'Required Documents',       admin_required_gov_documents_path }
              li { link_to 'Documents',                admin_gov_documents_path }
              li { link_to 'Links',                    admin_country_links_path }
              li { link_to 'Vpas',                     admin_country_vpas_path }
            end
          end
        end

        ul do
          li do
            text_node content_tag 'a', 'Static Content'
            ul do
              li { link_to 'Partners',           admin_partners_path }
              li { link_to 'Donors',             admin_donors_path }
              li do
                text_node content_tag 'a', 'Help page', class: '-with-children'
                ul do
                  li { link_to 'FAQs',               admin_faqs_path }
                  li { link_to 'How Tos',            admin_how_tos_path }
                  li { link_to 'Tools',              admin_tools_path }
                  li { link_to 'Tutorials',          admin_tutorials_path }
                  li { link_to 'Uploaded Documents', admin_uploaded_documents_path }
                end
              end
            end
          end
        end

        ul do
          li do
            text_node content_tag 'a', 'User Management'
            ul do
              li { link_to 'Users',              admin_users_path }
              li { link_to 'Access Control',     admin_access_control_path }
              li { link_to 'Contacts',           admin_contacts_path }
              li { link_to 'Comments',           admin_comments_path }
            end
          end
        end
      end
    end

    div class: 'c-nav' do
      div class: 'list' do
        ul class: 'user' do
          li { link_to @arbre_context.assigns[:current_user].email, admin_user_path(@arbre_context.assigns[:current_user].id) }
        end
        ul class: 'logout' do
          li { link_to ' Logout', destroy_user_session_path }
        end
      end
    end
  end
end
