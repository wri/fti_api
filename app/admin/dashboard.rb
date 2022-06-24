# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do

  # menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }
  menu false

  page_action :deploy_portal, method: :post do
    system 'rake deploy:portal' if current_user.user_permission.user_role == 'admin'
    redirect_to admin_dashboard_path, notice: 'Deploying Portal'
  end

  page_action :deploy_ot, method: :post do
    system 'rake deploy:tools' if current_user.user_permission.user_role == 'admin'
    redirect_to admin_dashboard_path, notice: 'Deploying IM Backoffice'
  end

  page_action :hide_old_observations, method: :post do
    system 'rake observations:hide' if current_user.user_permission.user_role == 'admin'
    redirect_to admin_dashboard_path, notice: 'Hiding old observations'
  end

  content title: proc{ I18n.t("active_admin.dashboard") } do
    if current_user.user_permission.user_role == 'admin'
      obs_count = Observation.where('publication_date < ? and hidden = false', Date.today - 5.year).count

      unless obs_count.zero?
        columns do
          button_to 'Hide old observations', '/admin/dashboard/hide_old_observations', method: :post,
                                                                                       data: { confirm: 'Are you sure you want to hide old observations?' },
                                                                                       class: 'deploy-button'
        end
        panel "Old observations (#{obs_count})" do
          table_for Observation.includes(:subcategory, :operator, country: :translations).where('publication_date < ?', Date.today - 5.year).order(publication_date: :desc).limit(20) do
            column('ID') { |obs| link_to obs.id, admin_observation_path(obs.id) }
            column('Publication Date') { |obs| obs.publication_date }
            column('Country') { |obs| obs.country }
            column('Subcategory') { |obs| obs.subcategory }
            column('Operator') { |obs| obs.operator }
            column('Date') { |obs| obs.publication_date.strftime("%A, %d/%b/%Y") }
          end
        end
      end

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
                                                                            data: { confirm: 'Are you sure you want to deploy the IM BACKOFFICE?' },
                                                                            class: 'deploy-button'
            #style: 'font-size: 1.5em'
          end
        end
      end
    end

    columns do
      column do
        panel 'New Producers' do
          table_for Operator.inactive.includes(country: :translations).order('updated_at DESC').limit(20).each do
            column('Name') { |o| link_to o.name, admin_producer_path(o.id) }
            column('Country') { |o| o.country.present? ? o.country.name : 'No country' }
          end
        end
      end

      column do
        panel 'New IMs' do
          table_for Observer.inactive.includes(countries: :translations).order('updated_at DESC').limit(20).each do
            column('Name') { |o| link_to o.name, admin_monitor_path(o.id) }
            column('Countries') { |o| o.countries.each{ |x| x.name }.join(', ') }
          end
        end
      end
    end


    columns do
      column do
        panel 'New User Accounts' do
          table_for User.inactive.includes(:user_permission, country: :translations).order('updated_at DESC').limit(20).each do
            column('Name')    { |o| link_to o.name, admin_user_path(o.id) }
            column('Country') { |o| o.country.name  if o.country.present? }
            column('Role')    { |o| o.user_permission.user_role if o.user_permission.present? }
          end
        end
      end

      column do
        panel "First 20 Pending Observations out of #{Observation.Created.count}" do
          table_for Observation.Created.includes(:country, :subcategory, :operator).order('updated_at DESC').limit(20).each do
            column('ID') { |obs| link_to obs.id, admin_observation_path(obs.id) }
            column('Country') { |obs| obs.country }
            column('Subcategory') { |obs| obs.subcategory }
            column('Operator') { |obs| obs.operator }
            column('Date') { |obs| obs.publication_date.strftime("%A, %d/%b/%Y") }
          end
        end
      end
    end


    columns do
      column do
        panel "First 20 Pending Documents out of #{OperatorDocument.doc_pending.count}" do
          table_for OperatorDocument.doc_pending.includes(:operator, :required_operator_document).order('updated_at DESC').limit(20).each do
            column('Operator') { |od| link_to od.operator.name, admin_producer_path(od.operator_id) }
            column('Name') { |od| link_to od.required_operator_document.name, admin_operator_document_path(od.id) }
            column('Creation Date') { |od| od.created_at.strftime("%A, %d/%b/%Y") }
          end
        end
      end

      column do
        panel "Last 20 Contact requests out of #{Contact.count}" do
          table_for Contact.order('created_at DESC').limit(20).each do
            column('Name')  { |c| link_to c.name, admin_contact_path(c.id) }
            column('Email') { |c| c.email }
            column('Date')  { |c| c.created_at }
          end
        end
      end
    end
    panel "Recently updated content" do
      table_for PaperTrail::Version.order(id: :desc).limit(20) do # Use PaperTrail::Version if this throws an error
        column("Item") { |v| v.item }
        # column ("Item") { |v| link_to v.item, [:admin, v.item] } # Uncomment to display as link
        column("Type") { |v| v.item_type.underscore.humanize }
        column("Modified at") { |v| v.created_at.to_s :long }
        column("Admin") { |v| link_to User.find(v.whodunnit).email, [:admin, User.find(v.whodunnit)] rescue '' }
      end
    end

  end
end
