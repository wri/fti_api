# frozen_string_literal: true

class EnambleCitextExtension < ActiveRecord::Migration[5.0]
  adapter_type = connection.adapter_name.downcase.to_sym
  case adapter_type
  when :postgresql
    def up
      execute 'CREATE EXTENSION IF NOT EXISTS "citext"'
      enable_extension 'citext'
    end

    def down
      disable_extension 'citext'
      execute 'DROP EXTENSION IF EXISTS "citext"'
    end
  else
    raise NotImplementedError, "Unknown adapter type '#{adapter_type}'"
  end
end
