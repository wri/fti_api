# frozen_string_literal: true

module ActiveAdmin
  # Wraps long index table cells in a clamp container on the server, so rows render at their
  # final three-line height from the first paint (styles in admin_theme/_components.scss,
  # click-to-expand in table_cells.js).
  module CellClampExtension
    SKIPPED_COLUMNS = %w[col-selectable col-actions].freeze
    INTERACTIVE_CONTENT = /<(input|select|textarea|button)\b|dropdown_menu|tag-select-container|table_actions/

    def build_table_cell(col, resource)
      cell = super
      return cell if SKIPPED_COLUMNS.any? { |name| col.html_class.to_s.split.include?(name) }

      inner = cell.children.to_s
      length = helpers.strip_tags(inner).squish.length
      return cell if length < 16 || inner.match?(INTERACTIVE_CONTENT)

      cell.children.clear
      within(cell) do
        div(class: (length >= 40) ? "cell-clamp cell-clamp--long" : "cell-clamp") { text_node inner.html_safe } # rubocop:disable Rails/OutputSafety
      end
      cell
    end
  end
end
