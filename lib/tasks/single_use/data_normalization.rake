namespace :normalize do
  # TODO: remove it after the data normalization is done
  task data: :environment do
    ActiveRecord::Base.transaction do
      User.unscoped.find_each do |user|
        %i[name].each { |attr| user.normalize_attribute(attr) }
        user.save!(validate: false)
      end

      Observer.unscoped.find_each do |observer|
        %i[name address information_name information_email information_phone data_name data_email data_phone].each do |attr|
          observer.normalize_attribute(attr)
        end
        observer.save!(validate: false)
      end

      Operator.unscoped.find_each do |operator|
        %i[name details address website].each { |attr| operator.normalize_attribute(attr) }
        operator.save!(validate: false)
      end
    end
  end
end
