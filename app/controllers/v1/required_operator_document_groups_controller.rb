module V1
  class RequiredOperatorDocumentGroupsController < ApplicationController

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'RequiredOperatorDocumentGroup'

  end
end
