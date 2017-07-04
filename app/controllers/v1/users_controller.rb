# frozen_string_literal: true

module V1
  class UsersController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'User'

    before_action :set_user, only: [:show, :update, :destroy]

  end
end
