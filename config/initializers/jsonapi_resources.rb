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
                  joins_query = _build_joins([records.model, *association])
                  joins_query << " LEFT JOIN #{association.name}_translations ON #{association.name}_translations.#{association.name}_id = #{association.name}_sorting.id AND #{association.name}_translations.locale = '#{_context[:locale]}'"
                  order_by_query = "#{association.name}_translations.#{column_name} #{direction}"
                  records = records.joins(joins_query).order(order_by_query)
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

  module ActsAsResourceController
    def render_results(operation_results)
      response_doc = create_response_document(operation_results)
      content = response_doc.contents

      render_options = {}
      if operation_results.has_errors?
        render_options[:json] = content
      else
        # Bypasing ActiveSupport allows us to use CompiledJson objects for cached response fragments
        render_options[:body] = JSON.generate(content)
      end

      if content[:data].is_a?(Hash) && content.dig(:data, :links, :self).present?
        render_options[:location] = content[:data]["links"][:self] if (
        response_doc.status == :created && content[:data].class != Array
        )
      end

      # For whatever reason, `render` ignores :status and :content_type when :body is set.
      # But, we can just set those values directly in the Response object instead.
      response.status = response_doc.status
      response.headers['Content-Type'] = JSONAPI::MEDIA_TYPE

      render(render_options)
    end
  end
end

