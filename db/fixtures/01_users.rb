# frozen_string_literal: true
unless User.find_by(nickname: 'admin')
  assign_country_id = if country = Country.find_by(iso: 'USA')
                        country.id
                      else
                        nil
                      end

  @user = User.new(email: 'admin@example.com', password: 'password', password_confirmation: 'password', name: 'Admin', nickname: 'admin', country_id: assign_country_id)
  @user.build_user_permission(user_role: 'admin')
  @user.save

  puts '*************************************************************************'
  puts '*                                                                       *'
  puts "* Admin user created (email: 'admin@example.com', password: 'password'  *"
  puts '* visit http://localhost:3000/                                          *'
  puts '*                                                                       *'
  puts '*************************************************************************'
end

# frozen_string_literal: true
unless User.find_by(nickname: 'user')
  assign_country_id = if country = Country.find_by(iso: 'USA')
                        country.id
                      else
                        nil
                      end

  @user = User.new(email: 'user@example.com', password: 'password', password_confirmation: 'password', name: 'User', nickname: 'user', country_id: assign_country_id, is_active: true)
  @user.build_user_permission(user_role: 'user')
  @user.save

  puts '*************************************************************************'
  puts '*                                                                       *'
  puts "* User created (email: 'user@example.com', password: 'password'         *"
  puts '*                                                                       *'
  puts '*************************************************************************'
end



unless User.find_by(nickname: 'webuser')
  assign_country_id = if country = Country.find_by(iso: 'USA')
                        country.id
                      else
                        nil
                      end

  @user = User.new(email: 'webuser@example.com', password: 'password', password_confirmation: 'password', name: 'Web', nickname: 'webuser', country_id: assign_country_id, is_active: true)
  @user.build_user_permission(user_role: 'user')
  @user.save
  @user.regenerate_api_key

  puts '*************************************************************************'
  puts '*                                                                       *'
  puts "* Web user created (email: 'webuser@example.com', password: 'password'  *"
  puts '*                                                                       *'
  puts "* API Key created (SC_API_KEY: Bearer #{@user.api_key.access_token})"
  puts '*                                                                       *'
  puts '*************************************************************************'
end

unless User.find_by(nickname: 'testngo')
  assign_country_id = if country = Country.find_by(iso: 'Congo')
                        country.id
                      else
                        nil
                      end

  @user = User.new(email: 'testngo@ngo.com', password: 'testpassword!ng0',
                   password_confirmation: 'testpassword!ng0', name: 'testngo',
                   nickname: 'testngo', country_id: assign_country_id, is_active: true)
  @user.build_user_permission(user_role: 'ngo')
  @user.save
  @user.regenerate_api_key

  puts '*************************************************************************'
  puts '*                                                                       *'
  puts "* Observer user created (email: 'testngo@ngo.com', password: 'password' *"
  puts '*                                                                       *'
  puts "* API Key created (SC_API_KEY: Bearer #{@user.api_key.access_token})"
  puts '*                                                                       *'
  puts '*************************************************************************'
end