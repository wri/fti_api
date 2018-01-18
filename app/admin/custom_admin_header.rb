class CustomAdminHeader < ActiveAdmin::Views::Header
  include Rails.application.routes.url_helpers

  def build(namespace, menu)
    div id: 'tabs' do
      # Add one item without son.
      ul do
        # Replace route_destination_path for the route you want to follow when you receive the item click.
        li { link_to 'Dashboard', admin_dashboard_path }
      end

      # Add one item with one son.
      ul do
        li do
          text_node content_tag 'a', 'Independent Monitoring'
          ul do
            li { link_to 'Monitors',         admin_monitors_path }
            li { link_to 'Observations',     admin_observations_path }
            li { link_to 'Reports',          admin_observation_reports_path }
            li { link_to 'Evidence',         admin_evidences_path }
            li do
              text_node content_tag 'a', 'Settings'
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

      # Adds a menu item with one son and one grandson.
      ul do
        li do
          text_node content_tag 'a', 'Private Sector'
          ul do
            li { link_to 'Producers',            admin_producers_path }
            li { link_to 'Document Categories',  admin_required_operator_document_groups_path }
            li { link_to 'Required Documents',   admin_required_operator_documents_path }
            li { link_to 'Producer Documents',   admin_operator_documents_path }
            li { link_to 'Annexes',              admin_operator_document_annexes_path }
            li do
              text_node content_tag 'a', 'Settings'
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
          text_node content_tag 'a', 'User Management'
          ul do
            li { link_to 'Users',            admin_users_path }
            li { link_to 'Access Control',   admin_access_control_path }
            li { link_to 'Contacts',         admin_contacts_path }
            li { link_to 'Partners',         admin_partners_path }
            li { link_to 'Comments',         admin_comments_path }
          end
        end
      end

      ul class: 'logout' do
        li { link_to ' Logout', destroy_user_session_path }
      end

      # Dashboard
      # Independent Monitoring
      # a. Monitors
      # b. Observations
      # c. Reports (current name Observation reports)
      # d. Evidence
      # e. Settings
      # i. Categories / ii. Subcategories / iii. Severities / iv. Laws / v. Government entities (current name Governments) / vi. Species
      # Private sector
      # a. Producers (current name Operators)
      # b. Documents categories (current name Required Operator Document Groups)
      # c. List of required documents (current name Required Operator Documents)
      # d. Producers documents (Operator Documents)
      # e. Annexes (current name Operator Document Annexes)
      # f. Settings
      # i. Countries / ii. FMUs / iii. Allocation of FMUs to Producers (current name Fmu Operators)
      # User management
      # a. Users / b. Access Control / c. Contacts / d. Partners / e. Comments

      # super(namespace, menu)
    end
  end
end
