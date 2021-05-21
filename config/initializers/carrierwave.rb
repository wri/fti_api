# frozen_string_literal: true

if Rails.env.test?
  CarrierWave.configure do |config|
    config.storage           = :file
    config.enable_processing = false
  end

  CarrierWave::Uploader::Base.descendants.each do |klass|
    next if klass.anonymous?

    klass.class_eval do
      def cache_dir
        Rails.root.join('spec', 'support', 'uploads', 'tmp')
      end

      def store_dir
        Rails.root.join('spec', 'support', 'uploads', "#{model.class.to_s.underscore}", "#{mounted_as}", "#{model.id}")
      end
    end
  end
end

CarrierWave.configure do |config|
  config.asset_host = ActionController::Base.asset_host
end
