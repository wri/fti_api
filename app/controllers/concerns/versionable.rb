# frozen_string_literal: true

module Versionable
  def self.extended(base)
    base.instance_eval do
      sidebar :versionate, partial: "version_sidebar", only: :show

      controller do
        def show
          model = resource.class.base_class
          resource = current = model.includes(versions: :item).find(params[:id])
          @versions = resource.versions.where.not(event: "create")
          @create_version = resource.versions.where(event: "create").first
          begin
            resource = @versions[params[:version].to_i].reify if params[:version]
          rescue => e
            Sentry.capture_exception e
          end
          # not sure why sometimes id is nil after reify
          resource.id = current.id if resource.id.nil?
          instance_variable_set("@#{resource_instance_name}", resource)
          show! # it seems to need this
        end
      end
    end
  end
end
