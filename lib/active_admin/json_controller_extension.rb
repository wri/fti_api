module ActiveAdmin
  module JsonControllerExtension
    def index
      if params[:fields].present?
        index! do |format|
          format.json do
            fields = params[:fields].split(',')
            render json: collection.as_json(only: fields)
          end
        end
      else
        super
      end
    end
  end
end
