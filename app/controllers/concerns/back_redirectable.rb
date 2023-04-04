# frozen_string_literal: true

module BackRedirectable
  # rubocop:disable Lint/NestedMethodDefinition
  def self.extended(base)
    base.controller do
      def update
        update! { params[:return_to] || collection_path }
      end

      def create
        create! { params[:return_to] || collection_path }
      end
    end
  end
  # rubocop:enable Lint/NestedMethodDefinition

  def form(options = {}, &block)
    if block.present?
      extended = proc do |f|
        return_to = request.params[:return_to] || request.referer
        f.hidden_field :return_to, name: :return_to, value: return_to if return_to.present?
        instance_eval(&block)
      end
      super(options, &extended)
    else
      super
    end
  end
end
