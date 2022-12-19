# frozen_string_literal: true

module Versionable
  def self.extended(base)
    base.sidebar :versionate, partial: 'layouts/version', only: :show
    base.controller do
      def show
        model = self.resource.class.base_class
        var_name = self.resource.class.base_class.to_s.underscore

        variable = model.includes(versions: :item).find(params[:id])
        @versions = variable.versions
        variable = variable.versions[params[:version].to_i].reify if params[:version]
        # rubocop:disable Security/Eval
        binding.eval("@#{var_name} = variable")
        # rubocop:enable Security/Eval
        show! #it seems to need this
      end
    end
  end
end
