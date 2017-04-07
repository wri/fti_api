# frozen_string_literal: true
unless User.find_by(nickname: 'webuser')
  assign_country_id = if country = Country.find_by(iso: 'USA')
                        country.id
                      else
                        nil
                      end

  @user = User.new(email: 'webuser@example.com', password: 'password', password_confirmation: 'password',
                   name: 'Web', nickname: 'webuser', country_id: assign_country_id, is_active: true)
  @user.save

  @user.regenerate_api_key

  puts '*************************************************************************'
  puts '*                                                                       *'
  puts "* Web user created (email: 'webuser@example.com', password: 'password'  *"
  puts '*                                                                       *'
  puts "* API Key created (OTP_API_KEY: Bearer #{@user.api_key.access_token})    *"
  puts '*                                                                       *'
  puts '*************************************************************************'
end
