module ActiveAdmin
  module DependentFiltersExtension
    def dependent_filters(&block)
      # sidebar won't be visible as css should hide it
      sidebar :dependent_filters, only: :index do
        filter_tree = block.call
        filter_tree.each_value { |v| v.transform_values! { |collection| HashHelper.aggregate(collection) } }

        render partial: 'dependent_filters', locals: { filter: filter_tree }
      end
    end
  end
end
