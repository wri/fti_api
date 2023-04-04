# frozen_string_literal: true

JSONAPI.configure do |config|
  # built in paginators are :none, :offset, :paged
  config.default_paginator = :paged
  config.default_page_size = 50
  config.maximum_page_size = 3000
  config.resource_cache = Rails.cache
  config.always_include_to_one_linkage_data = false
  config.warn_on_missing_routes = false
  config.default_exclude_links = :default

  # Metadata
  # Output record count in top level meta for find operation
  config.top_level_meta_include_record_count = true
  config.top_level_meta_record_count_key = :record_count
  config.top_level_meta_include_page_count = true
  config.top_level_meta_page_count_key = :page_count

  # The endpoints ignore params that are not allowed
  config.raise_if_parameters_not_allowed = false
end

# TODO: Not the perfect solution. Inspect the code of JSONAPIResources to find a better solution
module JSONAPI
  class ResourceSerializer
    def relationships_hash(source, fetchable_fields, include_directives = {})
      if source.is_a?(CachedResourceFragment)
        return cached_relationships_hash(source, include_directives)
      end

      include_directives[:include_related] ||= {}

      relationships = source.class._relationships.select { |k, v| fetchable_fields.include?(k) }
      field_set = supplying_relationship_fields(source.class) & relationships.keys

      relationships.each_with_object({}) do |(name, relationship), hash|
        ia = include_directives[:include_related][name]
        include_linkage = ia && ia[:include]
        include_linked_children = ia && !ia[:include_related].empty?

        if field_set.include?(name)
          # MONKEY PATCH to fix included objects relationships
          # from verions 0.9.7 there were no relationships for included objects
          # so including nested relations stopped working for example for observation subcategory.category
          hash[format_key(name)] = relationship_object(source, relationship, include_linkage)
          # following commented lines were in the original code
          # ro = relationship_object(source, relationship, include_linkage)
          # hash[format_key(name)] = ro unless ro.blank?
        end

        # If the object has been serialized once it will be in the related objects list,
        # but it's possible all children won't have been captured. So we must still go
        # through the relationships.
        if include_linkage || include_linked_children
          resources = if source.preloaded_fragments.key?(format_key(name))
            source.preloaded_fragments[format_key(name)].values
          else
            options = {filters: ia && ia[:include_filters] || {}}
            [source.public_send(name, options)].flatten(1).compact
          end
          resources.each do |resource|
            next if self_referential_and_already_in_source(resource)

            id = resource.id
            relationships_only = already_serialized?(relationship.type, id)
            if include_linkage && !relationships_only
              add_resource(resource, ia)
            elsif include_linked_children || relationships_only
              relationships_hash(resource, fetchable_fields, ia)
            end
          end
        end
      end
    end
  end

  class Resource
    class << self
      # rubocop:disable Lint/UnderscorePrefixedVariableName
      def apply_sort(records, order_options, _context = {})
        if order_options.any?
          order_options.each_pair do |field, direction|
            if field.to_s.include?(".")
              *model_names, column_name = field.split(".")
              association = _lookup_association_chain([records.model.to_s, *model_names]).last

              # MONKEY_PATCH to work with Globalize
              joins_query = _build_joins([records.model, *association])
              if defined?(association.klass.translated_attribute_names) &&
                  association.klass.translated_attribute_names.map(&:to_s).include?(column_name.to_s)
                joins_query << " LEFT JOIN #{association.name}_translations ON #{association.name}_translations.#{association.name}_id = #{association.name}_sorting.id AND #{association.name}_translations.locale = '#{_context[:locale]}'"
                order_by_query = "#{association.name}_translations.#{column_name} #{direction}"
              else
                # _sorting is appended to avoid name clashes with manual joins eg. overridden filters
                order_by_query = "#{association.name}_sorting.#{column_name} #{direction}"
              end
              records = records.joins(joins_query).order(order_by_query)
            else
              records = if @model_class.present? && defined?(@model_class.translated_attribute_names) &&
                  @model_class.translated_attribute_names.map(&:to_s).include?(field.to_s)
                records.joins(:translations).with_translations(_context[:locale])
                  .order("#{records.klass.translation_class.table_name}.#{field} #{direction}")
              else
                records.order(field => direction)
              end
            end
          end
        end
        records
      end
      # rubocop:enable Lint/UnderscorePrefixedVariableName
    end
  end
end
