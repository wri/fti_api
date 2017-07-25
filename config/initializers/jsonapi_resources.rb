JSONAPI.configure do |config|
  # built in paginators are :none, :offset, :paged
  config.default_paginator = :paged
  config.default_page_size = 50
  config.maximum_page_size = 3000
  config.resource_cache = Rails.cache
  config.always_include_to_one_linkage_data = false

  # Metadata
  # Output record count in top level meta for find operation
  config.top_level_meta_include_record_count = true
  config.top_level_meta_record_count_key = :record_count
  config.top_level_meta_include_page_count = true
  config.top_level_meta_page_count_key = :page_count
end

# TODO: Not the perfect solution. Inspect the code of JSONAPIResources to find a better solution
module JSONAPI
  class ResourceSerializer

    def link_object_to_many(source, relationship, include_linkage)
      include_linkage = include_linkage | relationship.always_include_linkage_data
      link_object_hash = {}
      link_object_hash[:links] = {} if relationship.always_include_linkage_data
      link_object_hash[:links][:self] = self_link(source, relationship) if relationship.always_include_linkage_data
      link_object_hash[:links][:related] = related_link(source, relationship) if relationship.always_include_linkage_data
      link_object_hash[:data] = to_many_linkage(source, relationship) if include_linkage
      link_object_hash
    end

    def link_object_to_one(source, relationship, include_linkage)
      include_linkage = include_linkage | @always_include_to_one_linkage_data | relationship.always_include_linkage_data
      link_object_hash = {}
      link_object_hash[:links] = {} if relationship.always_include_linkage_data
      link_object_hash[:links][:self] = self_link(source, relationship) if relationship.always_include_linkage_data
      link_object_hash[:links][:related] = related_link(source, relationship) if relationship.always_include_linkage_data
      link_object_hash[:data] = to_one_linkage(source, relationship) if include_linkage
      link_object_hash
    end
  end

  class Resource
    class << self
      def apply_sort(records, order_options, _context = {})
        if order_options.any?
          order_options.each_pair do |field, direction|
            if field.to_s.include?(".")
              *model_names, column_name = field.split(".")
              association = _lookup_association_chain([records.model.to_s, *model_names]).last

              if association.klass.attribute_names.include?(column_name)
                joins_query = _build_joins([records.model, *association])
                # _sorting is appended to avoid name clashes with manual joins eg. overridden filters
                order_by_query = "#{association.name}_sorting.#{column_name} #{direction}"
                records = records.joins(joins_query).order(order_by_query)
              else
                if association.klass.new.attributes.has_key?(column_name)
                  records = @model_class.joins("#{association.name.to_s}": :translations)
                                .where("#{association.name.to_s}_translations.locale = '#{_context[:locale]}'")
                                .order("lower(#{association.name.to_s}_translations.#{column_name}) #{direction}")
                end
              end
            else
              # Hack to work with Globalize
              if @model_class.attribute_names.include?(field)
                records = records.order(field => direction)
              else
                if @model_class.new.attributes.has_key?(field) # To check if it exists in the translations table
                  records = records.joins(:translations).with_translations(_context[:locale])
                              .order("#{records.klass.translation_class.table_name}.#{field} #{direction}")
                end
              end
            end
          end
        end

        records
      end
    end
  end
end

