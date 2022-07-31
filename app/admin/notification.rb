# frozen_string_literal: true

ActiveAdmin.register Notification do
  extend BackRedirectable
  back_redirect

  menu false

  scope :newly_created
  scope :seen
  scope :dismissed
  scope :solved

  actions :all, except: [:new, :edit, :update]

  index do
    selectable_column
    column :user
    column :operator
    column :operator_document do |resource|
      link_to(resource.operator_document.required_operator_document.name,
              admin_operator_document_path(resource.operator_document.id))
    end
    column :notification_group
    column :last_displayed_at
    column :dismissed_at
    column :solved_at
    column :expiration_date do |resource|
      resource.operator_document.expire_date
    end
    column :on_time? do |resource|
      expire_date = resource.operator_document.expire_date
      resource.solved_at || expire_date.blank? || expire_date > Date.today
    end
    column :created_at
    column :updated_at
    actions
  end
end
