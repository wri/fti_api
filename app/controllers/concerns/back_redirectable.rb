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
        update! do |format|
          redirect = session.delete(:return_to) || collection_path
          format.html { redirect_to redirect, notice: "#{resource.model_name.human} was successfully updated." }
        end
      end

      def create
        create! do |format|
          redirect = session.delete(:return_to) || collection_path
          format.html { redirect_to redirect, notice: "#{resource.model_name.human} was successfully created." }
        end
      end

    end
  end
end