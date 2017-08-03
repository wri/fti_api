module V1
  class OperatorDocumentsController < ApiController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'OperatorDocument'

    # TODO This is not the best method. Look for a better one
    def create
      if context[:current_user].present?
        if context[:current_user].operator_id.present?
          begin
            params['data']['attributes']['operator-id'] = context[:current_user].operator_id
          rescue
          end
        end
      end
      super
    end

    def destroy
      puts "coiso"
      super
    end
  end
end
