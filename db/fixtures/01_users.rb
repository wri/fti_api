# frozen_string_literal: true

unless User.find_by(nickname: "admin")
  assign_country_id = Country.find_by(iso: "USA")&.id

  @user = User.new(email: "admin@example.com", password: "password", password_confirmation: "password", name: "Admin", nickname: "admin", country_id: assign_country_id)
  @user.build_user_permission(user_role: "admin")
  @user.save

  Rails.logger.debug "*************************************************************************"
  Rails.logger.debug "*                                                                       *"
  Rails.logger.debug "* Admin user created (email: 'admin@example.com', password: 'password'  *"
  Rails.logger.debug "* visit http://localhost:3000/                                          *"
  Rails.logger.debug "*                                                                       *"
  Rails.logger.debug "*************************************************************************"
end

# frozen_string_literal: true
unless User.find_by(nickname: "user")
  assign_country_id = Country.find_by(iso: "USA")&.id

  @user = User.new(email: "user@example.com", password: "password", password_confirmation: "password", name: "User", nickname: "user", country_id: assign_country_id, is_active: true)
  @user.build_user_permission(user_role: "user")
  @user.save

  Rails.logger.debug "*************************************************************************"
  Rails.logger.debug "*                                                                       *"
  Rails.logger.debug "* User created (email: 'user@example.com', password: 'password'         *"
  Rails.logger.debug "*                                                                       *"
  Rails.logger.debug "*************************************************************************"
end

unless User.find_by(nickname: "webuser")
  assign_country_id = Country.find_by(iso: "USA")&.id

  @user = User.new(email: "webuser@example.com", password: "password", password_confirmation: "password", name: "Web", nickname: "webuser", country_id: assign_country_id, is_active: true)
  @user.build_user_permission(user_role: "user")
  @user.save
  @user.regenerate_api_key

  Rails.logger.debug "*************************************************************************"
  Rails.logger.debug "*                                                                       *"
  Rails.logger.debug "* Web user created (email: 'webuser@example.com', password: 'password'  *"
  Rails.logger.debug "*                                                                       *"
  Rails.logger.debug "* API Key created (SC_API_KEY: Bearer #{@user.api_key.access_token})"
  Rails.logger.debug "*                                                                       *"
  Rails.logger.debug "*************************************************************************"
end
