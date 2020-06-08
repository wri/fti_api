# frozen_string_literal: true

# Controller for the email contacts

module V1
  class ContactsController < ApiController

    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show, :create]

    # TODO: rubocop shouldn't disable this. Check this later.
    # rubocop:disable Lint/RescueException
    def create
      contact = Contact.new(contact_params)
      if contact.save
        begin
          MailService.newsletter contact.email
        rescue Exception => e
          Rails.logger.error "Error sending the email: #{e}"
        end
        render json: contact.to_json, status: :created
      else
        render json: contact.errors, status: :unprocessable_entity
      end
    end
    # rubocop:enable Lint/RescueException

    def index
      render json: Contact.all
    end
    
    private

    def contact_params
      params.require(:contact).permit(:email, :name)
    end
  end
end
