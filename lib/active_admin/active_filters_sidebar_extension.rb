module ActiveAdmin
  # fixes rendering of the current filters sidebar:
  # - proc labels of scope filters were not evaluated
  # - values not found in the related class (like "null" of the All Countries option)
  #   are resolved to their select collection labels instead of showing blank
  module ActiveFiltersSidebarExtension
    def filter_item(filter)
      li filter.html_options do
        span filter.label
        b to_sentence(filter_values(filter))
      end
    end

    def scope_item(name, value)
      filter_name = name.gsub(/_eq$/, "")
      filter_config = active_admin_config.filters[filter_name.to_sym]
      label = filter_config.try(:[], :label) || filter_name.titleize
      label = instance_exec(&label) if label.is_a?(Proc)

      li class: "current_filter_#{name}" do
        span "#{label} #{Ransack::Translate.predicate("eq")}"
        b collection_option_label(filter_config, value)
      end
    end

    private

    def filter_values(filter)
      values = filter.values.to_a
      return values.map { |value| pretty_format(value) } if values.present?

      filter_name = filter.condition.attributes.first.attr_name
      filter_config = active_admin_config.filters[filter_name.to_sym]
      filter.condition.values.map { |value| collection_option_label(filter_config, value.value) }
    end

    def collection_option_label(filter_config, value)
      collection = filter_config.try(:[], :collection)
      collection = instance_exec(&collection) if collection.is_a?(Proc)
      option = collection&.find { |o| o.is_a?(Array) && o.last.to_s == value.to_s }
      option ? option.first : value
    end
  end
end
