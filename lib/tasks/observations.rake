namespace :observations do
  desc 'Hide observations older than 5 year'
  task hide: :environment do
    Observation.where("publication_date < ?", Date.today - 5.years).update_all(hidden: true)
  end
end