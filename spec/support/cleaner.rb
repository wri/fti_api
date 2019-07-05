RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    #DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:all) do
    DatabaseCleaner.start
  end

  config.after(:all) do
    DatabaseCleaner.clean
  end

  config.after(:suite) do
    DatabaseCleaner.clean
  end
end
