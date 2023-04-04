unless User.find_by(nickname: "testngo")
  assign_country_id = if country = Country.find_by(iso: "COG")
    country.id
  end

  @user = User.new(email: "testngo@ngo.com", password: "testpassword!ng0",
    password_confirmation: "testpassword!ng0", name: "testngo",
    nickname: "testngo", country_id: assign_country_id, is_active: true,
    observer_id: 1)
  @user.build_user_permission(user_role: "ngo")
  @user.save
  @user.regenerate_api_key

  puts "*************************************************************************"
  puts "*                                                                       *"
  puts "* Observer user created (email: 'testngo@ngo.com', password: 'password' *"
  puts "*                                                                       *"
  puts "* API Key created (SC_API_KEY: Bearer #{@user.api_key.access_token})"
  puts "*                                                                       *"
  puts "*************************************************************************"
end
