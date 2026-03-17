# frozen_string_literal: true

module Versionable
  def self.extended(base)
    base.instance_eval do
      sidebar :version_info, partial: "version_sidebar", only: :show

      controller do
        helper_method :versions, :create_version

        def versions
          @versions
        end

        def create_version
          @create_version
        end

        def show
          model = resource.class.base_class
          current = if model.respond_to?(:with_deleted)
            model.includes(versions: :item).with_deleted.find(params[:id])
          else
            model.includes(versions: :item).find(params[:id])
          end
          @versions, @create_version = CombinedVersion.build_for(current)
          resource = current
          begin
            if params[:version]
              version = @versions[params[:version].to_i]
              resource = version.reify(current)
            end
          rescue => e
            Sentry.capture_exception e
            raise if Rails.env.local?
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
