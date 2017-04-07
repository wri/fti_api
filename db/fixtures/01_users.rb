# frozen_string_literal: true
unless User.find_by(nickname: 'admin')
  assign_country_id = if country = Country.find_by(iso: 'USA')
                        country.id
                      else
                        nil
                      end

  @user = User.new(email: 'admin@example.com', password: ENV['ADMIN_PASSWORD'], password_confirmation: ENV['ADMIN_PASSWORD'], name: 'Admin', nickname: 'admin', country_id: assign_country_id)
  @user.save
  @user.user_permission.update(user_role: 'admin', permissions: { admin: { all: [:read] }, all: { all: [:manage] } })

  puts '*************************************************************************'
  puts '*                                                                       *'
  puts "* Admin user created (email: 'admin@example.com', password: #{ENV['ADMIN_PASSWORD']})   *"
  puts '* visit http://localhost:3000/                                          *'
  puts '*                                                                       *'
  puts '*************************************************************************'
end
