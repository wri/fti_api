sh "bin/rails db:fixtures:load FIXTURES_PATH=db/fixtures"

unless User.find_by(email: "admin@example.com")
  user = User.new(email: "admin@example.com", password: "password", password_confirmation: "password", name: "Admin")
  user.build_user_permission(user_role: "admin")
  user.save!
end

# frozen_string_literal: true
unless User.find_by(email: "user@example.com")
  user = User.new(email: "user@example.com", password: "password", password_confirmation: "password", name: "User", is_active: true)
  user.build_user_permission(user_role: "user")
  user.save!
end

unless User.find_by(email: "webuser@example.com")
  user = User.new(email: "webuser@example.com", password: "password", password_confirmation: "password", name: "Web", is_active: true)
  user.build_user_permission(user_role: "user")
  user.save!
  user.regenerate_api_key
end

Rake::Task["sync:ranking"].invoke
Operator.find_each { |o| ScoreOperatorDocument.recalculate!(o) }
