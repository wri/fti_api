namespace :convert do

  desc 'Converts the current 1-M relationship of FMU-Operator to M-N'
  task fmu_operator: :environment do
    Fmu.find_each do |fmu|
      next unless fmu.operator_id.present?
      puts "FMU: #{fmu.name}"
      fmu_operator = FmuOperator.new(fmu_id: fmu.id, operator_id: fmu.operator_id, current: true, start_date: 2.years.ago)
      fmu_operator.save!
    end
    puts "Count: #{FmuOperator.count}"
  end
end