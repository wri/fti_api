class DependentSelectInput < ActiveAdmin::Inputs::Filters::SelectInput
  def input_html_options
    super.merge(
      # default-select class to not initialize select2 from activeadmin_addons
      class: 'default-select dependent-select',
      data: {
        dependent_on: options[:dependent_on],
        q: options[:query],
        url: url_from_options,
        order: order_from_options,
        id_field: options[:id_field] || options[:field],
        text_field: options[:text_field] || options[:field]
      }.compact
    )
  end

  private

  def order_from_options
    return options[:order] if options[:order].present?
    return "#{options[:field]}_asc" if options[:field].present?

    nil
  end

  def url_from_options
    if options[:url].is_a?(Proc)
      template.instance_exec(&options[:url])
    else
      options[:url]
    end
  end
end
