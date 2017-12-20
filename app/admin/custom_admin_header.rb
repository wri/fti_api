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
          text_node 'Independent Monitoring'
          ul do
            li { link_to 'Monitors', admin_monitors_path }
            # If you want to add more children, including more LIs here.
          end
        end
      end

      # Adds a menu item with one son and one grandson.
      ul do
        li do
          text_node 'Private Sector'
          ul do
            li do
              text_node link_to('Producers', admin_producers_path)
              ul do
                li { link_to 'Test', admin_observations_path }
                # If you want to add more grandchildren, including more LIs here.
              end
            end
          end
        end
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

      super(namespace, menu)
    end
  end
end