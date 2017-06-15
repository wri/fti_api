# Controller for the email contacts

module V1
  class ContactsController < ApplicationController

    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show, :create]

    def create
      contact = Contact.new(contact_params)
      if contact.save
        begin
          ContactMailer.welcome_email(contact.email, contact.name).deliver
        rescue Exception => e
          Rails.logger.error "Error sending the email: #{e}"
        end
        render json: contact.to_json, status: :created
      else
        render json: contact.errors, status: :unprocessable_entity
      end
    end

    def index
      render json: Contact.all
    end
    
    private

    def contact_params
      params.require(:contact).permit(:email, :name)
    end
  end
end