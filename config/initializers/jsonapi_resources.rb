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
end

