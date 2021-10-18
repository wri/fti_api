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
      include_linkage = include_linkage | @always_include_to_one_linkage_data | relationship.always_include_linkage_data
      link_object_hash = {}
      # MONKEY PATCH to show the links only if there's linkage data
      link_object_hash[:links] = {} if relationship.always_include_linkage_data
      link_object_hash[:links][:self] = self_link(source, relationship) if relationship.always_include_linkage_data
      link_object_hash[:links][:related] = related_link(source, relationship) if relationship.always_include_linkage_data
      link_object_hash[:data] = to_one_linkage(source, relationship) if include_linkage
      link_object_hash
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

      # READTHIS: MONKEY PATCH that adds this line  https://github.com/cerebris/jsonapi-resources/commit/0280f70ae481ac18b7abc659a6580a82b71d4175
      # only this was changed in that method to fix nil relationships error
      def preload_included_fragments(resources, records, serializer, options)
        return if resources.empty?

        res_ids = resources.keys

        include_directives = options[:include_directives]
        return unless include_directives

        context = options[:context]

        # For each association, including indirect associations, find the target record ids.
        # Even if a target class doesn't have caching enabled, we still have to look up
        # and match the target ids here, because we can't use ActiveRecord#includes.
        #
        # Note that `paths` returns partial paths before complete paths, so e.g. the partial
        # fragments for posts.comments will exist before we start working with posts.comments.author
        target_resources = {}
        include_directives.paths.each do |path|
          # If path is [:posts, :comments, :author], then...
          pluck_attrs = [] # ...will be [posts.id, comments.id, authors.id, authors.updated_at]
          pluck_attrs << self._model_class.arel_table[self._primary_key]

          relation = records
            .except(:limit, :offset, :order)
            .where({ _primary_key => res_ids })

          # These are updated as we iterate through the association path; afterwards they will
          # refer to the final resource on the path, i.e. the actual resource to find in the cache.
          # So e.g. if path is [:posts, :comments, :author], then after iteration...
          parent_klass = nil # Comment
          klass = self # Person
          relationship = nil # JSONAPI::Relationship::ToOne for CommentResource.author
          table = nil # people
          assocs_path = [] # [ :posts, :approved_comments, :author ]
          ar_hash = nil # { :posts => { :approved_comments => :author } }

          # For each step on the path, figure out what the actual table name/alias in the join
          # will be, and include the primary key of that table in our list of fields to select
          non_polymorphic = true
          path.each do |elem|
            relationship = klass._relationships[elem]
            if relationship.polymorphic
              # Can't preload through a polymorphic belongs_to association, ResourceSerializer
              # will just have to bypass the cache and load the real Resource.
              non_polymorphic = false
              break
            end
            assocs_path << relationship.relation_name(options).to_sym
            # Converts [:a, :b, :c] to Rails-style { :a => { :b => :c }}
            ar_hash = assocs_path.reverse.reduce{ |memo, step| { step => memo } }
            # We can't just look up the table name from the resource class, because Arel could
            # have used a table alias if the relation includes a self-reference.
            join_source = relation.joins(ar_hash).arel.source.right.reverse.find do |arel_node|
              arel_node.is_a?(Arel::Nodes::InnerJoin)
            end
            table = join_source.left
            parent_klass = klass
            klass = relationship.resource_klass
            pluck_attrs << table[klass._primary_key]
          end
          next unless non_polymorphic

          # Pre-fill empty hashes for each resource up to the end of the path.
          # This allows us to later distinguish between a preload that returned nothing
          # vs. a preload that never ran.
          prefilling_resources = resources.values
          path.each do |rel_name|
            rel_name = serializer.key_formatter.format(rel_name)
            prefilling_resources.map! do |res|
              res.preloaded_fragments[rel_name] ||= {}
              res.preloaded_fragments[rel_name].values
            end
            prefilling_resources.flatten!(1)
          end

          pluck_attrs << table[klass._cache_field] if klass.caching?
          relation = relation.joins(ar_hash)
          if relationship.is_a?(JSONAPI::Relationship::ToMany)
            # Rails doesn't include order clauses in `joins`, so we have to add that manually here.
            # FIXME Should find a better way to reflect on relationship ordering. :-(
            relation = relation.order(parent_klass._model_class.new.send(assocs_path.last).arel.orders)
          end

          # [[post id, comment id, author id, author updated_at], ...]
          id_rows = pluck_arel_attributes(relation.joins(ar_hash), *pluck_attrs)

          target_resources[klass.name] ||= {}

          if klass.caching?
            sub_cache_ids = id_rows
              .map{ |row| row.last(2) }
              .reject{ |row| target_resources[klass.name].key?(row.first) }
              .uniq
            target_resources[klass.name].merge! CachedResourceFragment.fetch_fragments(
              klass, serializer, context, sub_cache_ids
            )
          else
            sub_res_ids = id_rows
              .map(&:last)
              .reject{ |id| target_resources[klass.name].key?(id) }
              .uniq
            found = klass.find({ klass._primary_key => sub_res_ids }, context: options[:context])
            target_resources[klass.name].merge! found.map{ |r| [r.id, r] }.to_h
          end

          id_rows.each do |row|
            res = resources[row.first]
            path.each_with_index do |rel_name, index|
              rel_name = serializer.key_formatter.format(rel_name)
              rel_id = row[index+1]
              assoc_rels = res.preloaded_fragments[rel_name]
              if index == path.length - 1
                association_res = target_resources[klass.name].fetch(rel_id, nil)
                assoc_rels[rel_id] = association_res if association_res
              else
                res = assoc_rels[rel_id]
              end
            end
          end
        end
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
