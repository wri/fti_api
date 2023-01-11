# frozen_string_literal: true

module Versionable
  def self.extended(base)
    base.instance_eval do
      sidebar :versionate, partial: 'layouts/version', only: :show

      controller do
        def show
          model = resource.class.base_class
          variable = model.includes(versions: :item).find(params[:id])
          @versions = variable.versions.where.not(event: 'create')
          begin
            variable = @versions[params[:version].to_i].reify if params[:version]
          rescue StandardError => e
            Sentry.capture_exception e
          end
          instance_variable_set("@#{resource_instance_name}", variable)
          show! #it seems to need this
        end
      end
    end
  end
end
