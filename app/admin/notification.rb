# frozen_string_literal: true

ActiveAdmin.register Notification do
  extend BackRedirectable

  menu false

  scope :newly_created
  scope :seen
  scope :dismissed
  scope :solved

  filter :notification_group
  filter :operator_document_operator_id,
         as: :select,
         label: 'Operator',
         collection: -> { Operator.order(:name) }
  filter :user
  filter :last_displayed_at
  filter :dismissed_at
  filter :solved_at

  actions :all, except: [:new, :edit, :update]

  controller do
    def scoped_collection
      end_of_association_chain.includes(:user, :notification_group,
                                        operator_document: [:operator, required_operator_document: [:translations]])
    end
  end


  index do
    selectable_column
    column :user
    column :operator do |resource|
      link_to(resource.operator_document.operator.name,
              admin_producer_path(resource.operator_document.operator))
    end
    column :operator_document do |resource|
      link_to(resource.operator_document.required_operator_document.name,
              admin_operator_document_path(resource.operator_document))
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
