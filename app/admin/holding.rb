# frozen_string_literal: true

ActiveAdmin.register Holding do
  extend BackRedirectable

  menu false

  config.order_clause

  permit_params :name

  sidebar :producers, only: :show do
    sidebar = Operator.where(holding: resource).collect do |op|
      auto_link(op, op.name.camelize)
    end
    safe_join(sidebar, content_tag('br'))
  end
end
