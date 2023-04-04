# frozen_string_literal: true

module Versionable
  def self.extended(base)
    base.instance_eval do
      sidebar :versionate, partial: "layouts/version", only: :show

      controller do
        def show
          model = resource.class.base_class
          variable = current = model.includes(versions: :item).find(params[:id])
          @versions = variable.versions.where.not(event: "create")
          @create_version = variable.versions.where(event: "create").first
          begin
            variable = @versions[params[:version].to_i].reify if params[:version]
          rescue => e
            Sentry.capture_exception e
          end
          # not sure why sometimes id is nil after reify
          variable.id = current.id if variable.id.nil?
          instance_variable_set("@#{resource_instance_name}", variable)
          show! # it seems to need this
        end
      end
    end
  end
end
