# frozen_string_literal: true

# AMS Adapter
ActiveModelSerializers.config.adapter = ActiveModelSerializers::Adapter::JsonApi
ActiveModelSerializers.config.key_transform = :unaltered
