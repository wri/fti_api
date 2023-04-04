module APIDocsHelpers
  def add_sort_parameter
    parameter :sort, "Sort order", type: :string, required: false
  end

  def add_include_parameter(options = {})
    parameter :include, "related relationships to include: " + options[:example].join(", "),
      type: :string,
      required: false,
      example: options[:example]
    let(:include) { nil } # otherwise it would always take built-in rspec matcher include
  end

  def add_paging_parameters
    parameter "page[limit]", "max number of items", type: :integer, required: false
    parameter "page[offset]", "page offset", type: :integer, required: false
    parameter "page[number]", "page number", type: :integer, required: false
    parameter "page[size]", "the number of resources to be returned per page",
      type: :integer,
      required: false
  end

  def add_filter_parameters_for(resource)
    resource.filters.keys.each do |filter|
      parameter "filter[#{filter}]", "filter by #{filter}",
        type: :string,
        required: false
    end
  end

  def add_field_parameter_for(model)
    parameter "fields[#{model.to_s.pluralize}]",
      "a comma separated list of #{model} attributes you wish to limit (must be dasherized)",
      type: :string, required: false
  end
end
