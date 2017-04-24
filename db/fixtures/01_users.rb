# frozen_string_literal: true
unless User.find_by(nickname: 'admin')
  assign_country_id = if country = Country.find_by(iso: 'USA')
                        country.id
                      else
                        nil
                      end

  @user = User.new(email: 'admin@example.com', password: 'password', password_confirmation: 'password', name: 'Admin', nickname: 'admin', country_id: assign_country_id)
  @user.save
  @user.user_permission.update(user_role: 'admin')

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
  @user.save

  puts '*************************************************************************'
  puts '*                                                                       *'
  puts "* User created (email: 'user@example.com', password: 'password'         *"
  puts '*                                                                       *'
  puts '*************************************************************************'
end

unless User.find_by(nickname: 'ngo')
  assign_country_id = if country = Country.find_by(iso: 'USA')
                        country.id
                      else
                        nil
                      end

  @user = User.new(email: 'ngo@example.com', password: 'password', password_confirmation: 'password', name: 'NGO', nickname: 'ngo', country_id: assign_country_id, is_active: true)
  @user.save
  @user.user_permission.update(user_role: 'ngo')

  puts '*************************************************************************'
  puts '*                                                                       *'
  puts "* NGO created (email: 'ngo@example.com', password: 'password'           *"
  puts '*                                                                       *'
  puts '*************************************************************************'
end

unless User.find_by(nickname: 'operator')
  assign_country_id = if country = Country.find_by(iso: 'USA')
                        country.id
                      else
                        nil
                      end

  @user = User.new(email: 'operator@example.com', password: 'password', password_confirmation: 'password', name: 'Operator', nickname: 'operator', country_id: assign_country_id, is_active: true)
  @user.save
  @user.user_permission.update(user_role: 'operator')

  puts '***************************************************************************'
  puts '*                                                                         *'
  puts "* Operator created (email: 'operator@example.com', password: 'password'   *"
  puts '*                                                                         *'
  puts '***************************************************************************'
end

unless User.find_by(nickname: 'webuser')
  assign_country_id = if country = Country.find_by(iso: 'USA')
                        country.id
                      else
                        nil
                      end

  @user = User.new(email: 'webuser@example.com', password: 'password', password_confirmation: 'password', name: 'Web', nickname: 'webuser', country_id: assign_country_id, is_active: true)
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
