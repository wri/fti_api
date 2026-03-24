# frozen_string_literal: true

module Versionable
  def self.extended(base)
    base.instance_eval do
      sidebar :version_info, partial: "version_sidebar", only: :show

      controller do
        helper_method :versions

        def versions
          @versions
        end

        def show
          current = find_current_record
          @versions = CombinedVersion.build_for(current)
          resource = current
          begin
            if params[:version]
              version = @versions[params[:version].to_i]
              resource = version.next.reify(current)
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

        private

        def find_current_record
          model = resource.class.base_class
          if model.respond_to?(:with_deleted)
            model.includes(versions: :item).with_deleted.find(params[:id])
          else
            model.includes(versions: :item).find(params[:id])
          end
        end
      end

      member_action :version_history do
        current = find_current_record
        versions = CombinedVersion.build_for(current)
        render partial: "version_history",
          locals: {versions: versions, resource: current},
          layout: false
      end
    end
  end
end
