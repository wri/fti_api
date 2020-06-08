# frozen_string_literal: true

module BackRedirectable
  def back_redirect
    controller do
      def edit
        session[:return_to] ||= request.referer
        super
      end

      def new
        session[:return_to] ||= request.referer
        super
      end

      def update
        update! do |success, failure|
          success.html do
            redirect = session.delete(:return_to) || collection_path
            redirect_to redirect, notice: "#{resource.model_name.human} was successfully updated."
          end
        end
      end

      def create
        create! do |success, failure|
          success.html do
            redirect = session.delete(:return_to) || collection_path
            redirect_to redirect, notice: "#{resource.model_name.human} was successfully created."
          end
        end
      end

    end
  end
end
