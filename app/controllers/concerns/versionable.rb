# frozen_string_literal: true

module Versionable
  def versionate
    sidebar :versionate, partial: 'layouts/version', only: :show
    controller do
      def show
        model = self.resource.class.base_class
        var_name = self.resource.class.base_class.to_s.underscore

        variable = model.includes(versions: :item).find(params[:id])
        @versions = variable.versions
        variable = variable.versions[params[:version].to_i].reify if params[:version]
        eval("@#{var_name} = variable")
        show! #it seems to need this
      end
    end
  end
end
