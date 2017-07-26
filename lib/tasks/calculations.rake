namespace :documents do
  desc 'Updates the percentage'
  task percentages: :environment do
    Operator.find_each { |x| x.update_valid_documents_percentages }
  end
end