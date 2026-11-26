# frozen_string_literal: true

# Renders the "Jump to page" field at the top of every filter form on the server
# (previously inserted by JavaScript after load, which pushed the sidebar down).
module ActiveAdminFilterJumpToPage
  def active_admin_filters_form_for(search, filters, options = {})
    form = super
    field = content_tag(:div, class: "input optional filter_form_field", id: "goto_page_input") do
      label_tag("hidden_active_admin_goto_page", I18n.t("active_admin.js.jump_to_page"), class: "label") +
        number_field_tag("page", nil, id: "hidden_active_admin_goto_page")
    end
    form.sub(/<form\b[^>]*>/) { |open_tag| open_tag + field }.html_safe # rubocop:disable Rails/OutputSafety
  end
end

ActiveAdmin::Filters::ViewHelper.prepend(ActiveAdminFilterJumpToPage)
