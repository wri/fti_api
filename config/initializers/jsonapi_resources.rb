# frozen_string_literal: true

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

  # The endpoints ignore params that are not allowed
  config.raise_if_parameters_not_allowed = false
end

# TODO: Not the perfect solution. Inspect the code of JSONAPIResources to find a better solution
module JSONAPI
  class ResourceSerializer

    def link_object_to_many(source, relationship, include_linkage)
      #byebug
      include_linkage = include_linkage | relationship.always_include_linkage_data
      link_object_hash = {}
      # MONKEY_PATCH to show the links only if there's linkage data
      link_object_hash[:links] = {} if relationship.always_include_linkage_data
      link_object_hash[:links][:self] = self_link(source, relationship) if relationship.always_include_linkage_data
      link_object_hash[:links][:related] = related_link(source, relationship) if relationship.always_include_linkage_data
      link_object_hash[:data] = to_many_linkage(source, relationship) if include_linkage
      link_object_hash
    end

    def link_object_to_one(source, relationship, include_linkage)
      #byebug
      include_linkage = include_linkage | @always_include_to_one_linkage_data | relationship.always_include_linkage_data
      link_object_hash = {}
      # MONKEY PATCH to show the links only if there's linkage data
      link_object_hash[:links] = {} if relationship.always_include_linkage_data
      link_object_hash[:links][:self] = self_link(source, relationship) if relationship.always_include_linkage_data
      link_object_hash[:links][:related] = related_link(source, relationship) if relationship.always_include_linkage_data
      link_object_hash[:data] = to_one_linkage(source, relationship) if include_linkage
      link_object_hash
    end

    # def add_resource(source, include_directives, primary = false)
    #   #byebug
    #   type = source.is_a?(JSONAPI::CachedResourceFragment) ? source.type : source.class._type
    #   id = source.id

    #   @included_objects[type] ||= {}
    #   existing = @included_objects[type][id]

    #   if existing.nil?
    #     obj_hash = object_hash(source, include_directives)
    #     #aqui peta!!!
    #     @included_objects[type][id] = {
    #         primary: primary,
    #         object_hash: obj_hash,
    #         includes: Set.new(include_directives[:include_related].keys)
    #     }
    #   else
    #     include_related = Set.new(include_directives[:include_related].keys)
    #     unless existing[:includes].superset?(include_related)
    #       obj_hash = object_hash(source, include_directives)
    #       @included_objects[type][id][:object_hash].deep_merge!(obj_hash)
    #       @included_objects[type][id][:includes].add(include_related)
    #       @included_objects[type][id][:primary] = existing[:primary] | primary
    #     end
    #   end
    # end

    # def object_hash(source, include_directives = {})
    #   #byebug
    #   obj_hash = {}
    #   #return obj_hash if source[1].nil?

    #   if source.is_a?(JSONAPI::CachedResourceFragment)
    #     obj_hash['id'] = source.id
    #     obj_hash['type'] = source.type

    #     obj_hash['links'] = source.links_json if source.links_json
    #     obj_hash['attributes'] = source.attributes_json if source.attributes_json

    #     relationships = cached_relationships_hash(source, include_directives)
    #     obj_hash['relationships'] = relationships unless relationships.empty?

    #     obj_hash['meta'] = source.meta_json if source.meta_json
    #   else
    #     fetchable_fields = Set.new(source.fetchable_fields)

    #     # TODO Should this maybe be using @id_formatter instead, for consistency?
    #     id_format = source.class._attribute_options(:id)[:format]
    #     # protect against ids that were declared as an attribute, but did not have a format set.
    #     id_format = 'id' if id_format == :default
    #     obj_hash['id'] = format_value(source.id, id_format)

    #     obj_hash['type'] = format_key(source.class._type.to_s)

    #     links = links_hash(source)
    #     obj_hash['links'] = links unless links.empty?

    #     attributes = attributes_hash(source, fetchable_fields)
    #     obj_hash['attributes'] = attributes unless attributes.empty?

    #     relationships = relationships_hash(source, fetchable_fields, include_directives)
    #     obj_hash['relationships'] = relationships unless relationships.nil? || relationships.empty?

    #     meta = meta_hash(source)
    #     obj_hash['meta'] = meta unless meta.empty?
    #   end

    #   obj_hash
    # end

    # def cached_relationships_hash(source, include_directives)
    #   h = source.relationships || {}
    #   return h unless include_directives.has_key?(:include_related)

    #   relationships = source.resource_klass._relationships.select do |k,v|
    #     source.fetchable_fields.include?(k)
    #   end

    #   real_res = nil
    #   relationships.each do |rel_name, relationship|
    #     key = @key_formatter.format(rel_name)
    #     to_many = relationship.is_a? JSONAPI::Relationship::ToMany

    #     ia = include_directives[:include_related][rel_name]
    #     if ia
    #       if h.has_key?(key)
    #         h[key][:data] = to_many ? [] : nil
    #       end
    #       #byebug
    #       fragments = source.preloaded_fragments[key]

          
    #       if fragments.nil?
    #         # The resources we want were not preloaded, we'll have to bypass the cache.
    #         # This happens when including through belongs_to polymorphic relationships
    #         if real_res.nil?
    #           real_res = source.to_real_resource
    #         end
    #         relation_resources = [real_res.public_send(rel_name)].flatten(1).compact
    #         fragments = relation_resources.map{|r| [r.id, r]}.to_h
    #       end
    #       fragments.each do |id, f|
    #         next if f.nil?
    #         add_resource(f, ia)

    #         if h.has_key?(key)
    #           # The hash already has everything we need except the :data field
    #           data = {
    #             type: format_key(f.is_a?(Resource) ? f.class._type : f.type),
    #             id: @id_formatter.format(id)
    #           }

    #           if to_many
    #             h[key][:data] << data
    #           else
    #             h[key][:data] = data
    #           end
    #         end
    #       end
    #     end
    #   end

    #   return h
    # end

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
              if association.klass.attribute_names.include?(column_name)
                joins_query = _build_joins([records.model, *association])
                # _sorting is appended to avoid name clashes with manual joins eg. overridden filters
                order_by_query = "#{association.name}_sorting.#{column_name} #{direction}"
                records = records.joins(joins_query).order(order_by_query)
              else
                if association.klass.new.attributes.key?(column_name)
                  joins_query = _build_joins([records.model, *association])
                  joins_query << " LEFT JOIN #{association.name}_translations ON #{association.name}_translations.#{association.name}_id = #{association.name}_sorting.id AND #{association.name}_translations.locale = '#{_context[:locale]}'"
                  order_by_query = "#{association.name}_translations.#{column_name} #{direction}"
                  records = records.joins(joins_query).order(order_by_query)
                end
              end
            else
              # Hack to work with Globalize
              if @model_class&.attribute_names&.include?(field)
                records = records.order(field => direction)
              else
                if @model_class&.new&.attributes&.key?(field) # To check if it exists in the translations table
                  records = records.joins(:translations).with_translations(_context[:locale])
                              .order("#{records.klass.translation_class.table_name}.#{field} #{direction}")
                end
              end
            end
          end
        end
        records
      end
      # rubocop:enable Lint/UnderscorePrefixedVariableName
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

      # MONKEY PATCH : To allow the gem to work without links
      if content[:data].is_a?(Hash) && content.dig(:data, :links, :self).present?
        render_options[:location] = content[:data]["links"][:self] if
        response_doc.status == :created && content[:data].class != Array

      end

      # For whatever reason, `render` ignores :status and :content_type when :body is set.
      # But, we can just set those values directly in the Response object instead.
      response.status = response_doc.status
      response.headers['Content-Type'] = JSONAPI::MEDIA_TYPE

      render(render_options)
    end
  end
end
