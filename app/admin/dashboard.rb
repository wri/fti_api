ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do
    # div class: "blank_slate_container", id: "dashboard_default_message" do
    #   span class: "blank_slate" do
    #     span I18n.t("active_admin.dashboard_welcome.welcome")
    #     small I18n.t("active_admin.dashboard_welcome.call_to_action")
    #   end
    # end

    # Here is an example of a simple dashboard with columns and panels.

    columns do
      column do
        panel 'Pending Observations' do
          ul do
            Observation.Created.order(:updated_at).map do |obs|
              li link_to(obs.details, admin_observation_path(obs))
            end
          end
        end
      end

      column do
        panel 'Pending Documents' do
          ul do
            OperatorDocument.doc_pending.order(:updated_at).map do |od|
              li link_to("#{od.operator.name} - #{od.required_operator_document.name}", admin_operator_document_path(od))
            end
          end
        end
      end

      # column do
      #   panel "Recent Orders" do
      #     table_for Order.complete.order("id desc").limit(10) do
      #      column("State") { |order| status_tag(order.state) }
      #       column("Customer") { |order| link_to(order.user.email, admin_user_path(order.user)) }
      #       column("Total")   { |order| number_to_currency order.total_price }
      #    end
      #  end

    end
  end # content
end
