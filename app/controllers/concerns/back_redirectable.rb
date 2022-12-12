# frozen_string_literal: true

module BackRedirectable
  def back_redirect
    controller do
      def update
        update! do |success, failure|
          success.html do
            redirect = params[:return_to] || collection_path
            redirect_to redirect, notice: "#{resource.model_name.human} was successfully updated."
          end
        end
      end

      def create
        create! do |success, failure|
          success.html do
            redirect = params[:return_to] || collection_path
            redirect_to redirect, notice: "#{resource.model_name.human} was successfully created."
          end
        end
      end
    end
  end

  def form(options = {}, &block)
    if block.present?
      extended = Proc.new do |f|
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
