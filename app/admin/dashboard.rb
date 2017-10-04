ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  page_action :deploy_portal, method: :post do
    system 'rake deploy:portal' if current_user.user_permission.user_role == 'admin'
    redirect_to admin_dashboard_path, notice: 'Deploying Portal'
  end

  page_action :deploy_ot, method: :post do
    system 'rake deploy:tools' if current_user.user_permission.user_role == 'admin'
    redirect_to admin_dashboard_path, notice: 'Deploying IM Backoffice'
  end

  content title: proc{ I18n.t("active_admin.dashboard") } do
    if current_user.user_permission.user_role == 'admin'
      columns do
        column do
          panel 'Portal' do
            button_to 'Deploy Portal', '/admin/dashboard/deploy_portal', method: :post,
                      data: { confirm: 'Are you sure you want to deploy the PORTAL?' },
                      class: 'deploy-button'
                      #style: 'font-size: 1.5em'
          end
        end

        column do
          panel 'IM Backoffice' do
            button_to 'Deploy IM Backoffice', '/admin/dashboard/deploy_ot', method: :post,
                      data: { confirm: 'Are you sure you want to deploy the IM BACKOFFICE?'},
                      class: 'deploy-button'
                      #style: 'font-size: 1.5em'
          end
        end
      end
    end

    columns do
      column do
        panel "First 20 Pending Observations out of #{Observation.Created.count}" do
          table_for Observation.Created.order('updated_at DESC').limit(20).each do
            column('ID') { |obs| link_to obs.id, admin_observation_path(obs.id) }
            column('Country') {|obs| obs.country }
            column('Subcategory') {|obs| obs.subcategory }
            column('Operator') {|obs| obs.operator }
            column('Date') {|obs| obs.publication_date.strftime("%A, %d/%b/%Y") }

          end
        end
      end

      column do
        panel "First 20 Pending Documents out of #{OperatorDocument.doc_pending.count}" do
          table_for OperatorDocument.doc_pending.order('updated_at DESC').limit(20).each do
            column('Operator') { |od| link_to od.operator.name, admin_operator_path(od.operator_id) }
            column('Name') { |od| link_to od.required_operator_document.name, admin_operator_document_path(od.id) }
            column('Creation Date') { |od| od.created_at.strftime("%A, %d/%b/%Y") }
          end
        end
      end
    end

    columns do
      column do
        panel 'Operator Requests' do
          table_for Operator.inactive.order('updated_at DESC').limit(20).each do
            column('Name') { |o| link_to o.name, admin_operator_path(o.id) }
            column('Country') { |o| o.country.name }
          end
        end
      end

      column
    end
  end # content
end
