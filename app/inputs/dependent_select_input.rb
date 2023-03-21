class DependentSelectInput < ActiveAdmin::Inputs::Filters::SelectInput
  def initialize(*args)
    super
    options[:collection] = [] if options[:collection].nil?
  end

  def input_html_options
    super.merge(
      # default-select class to not initialize select2 from activeadmin_addons
      class: 'default-select dependent-select',
      data: {
        q: options[:query],
        url: url_from_options,
        order: order_from_options,
        tags: options[:free_text_search],
        id_field: options[:id_field] || options[:field] || 'id',
        text_field: text_field_from_options
      }.compact
    )
  end

  def raw_collection
    field_value = begin
                    object.send(method)
                  rescue NoMethodError
                    nil
                  end

    field_value.present? ? (super.to_a << field_value).uniq : super
  end

  private

  def order_from_options
    return options[:order] if options[:order].present?
    return "#{text_field_from_options}_asc" if text_field_from_options.present?

    nil
  end

  def text_field_from_options
    options[:text_field] || options[:field] || 'name'
  end

  def url_from_options
    if options[:url].is_a?(Proc)
      template.instance_exec(&options[:url])
    else
      options[:url]
    end
  end
end
