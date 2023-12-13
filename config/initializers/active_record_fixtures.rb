require "active_record/fixtures"

module FixtureSetExtension
  extend ActiveSupport::Concern

  class_methods do
    def insert(fixture_sets, connection) # :nodoc:
      fixture_sets_by_connection = fixture_sets.group_by do |fixture_set|
        if fixture_set.model_class
          fixture_set.model_class.connection
        else
          connection.call
        end
      end

      fixture_sets_by_connection.each do |conn, set|
        table_rows_for_connection = Hash.new { |h, k| h[k] = [] }

        set.each do |fixture_set|
          fixture_set.table_rows.each do |table, rows|
            table_rows_for_connection[table].unshift(*rows)
          end
        end

        conn.insert_fixtures_set(table_rows_for_connection, table_rows_for_connection.keys)

        check_all_foreign_keys_valid!(conn)

        # Cap primary key sequences to max(pk).
        if conn.respond_to?(:reset_pk_sequence!)
          set.each { |fs| conn.reset_pk_sequence!(fs.table_name) }
        end
      end
    end

    def check_all_foreign_keys_valid!(conn)
      return unless ActiveRecord.verify_foreign_keys_for_fixtures

      begin
        conn.check_all_foreign_keys_valid!
      rescue ActiveRecord::StatementInvalid => e
        raise "Foreign key violations found in your fixture data. Ensure you aren't referring to labels that don't exist on associations. Error from database:\n\n#{e.message}"
      end
    end
  end
end

module IntegrityExtension
  extend ActiveSupport::Concern

  def check_all_foreign_keys_valid! # :nodoc:
    sql = <<~SQL
      do $$
        declare r record;
      BEGIN
      FOR r IN (
        SELECT FORMAT(
          'UPDATE pg_constraint SET convalidated=false WHERE conname = ''%I'' AND connamespace::regnamespace = ''%I''::regnamespace; ALTER TABLE %I.%I VALIDATE CONSTRAINT %I;',
          constraint_name,
          table_schema,
          table_schema,
          table_name,
          constraint_name
        ) AS constraint_check
        FROM information_schema.table_constraints WHERE constraint_type = 'FOREIGN KEY'
      )
        LOOP
          EXECUTE (r.constraint_check);
        END LOOP;
      END;
      $$;
    SQL

    transaction(requires_new: true) do
      execute(sql)
    end
  end
end

# TODO: Remove when upgrading to Rails 7.1
# uncomment below extensions if you have problems with finding errors in data integrity of your fixtures
ActiveSupport::Reloader.to_prepare do
  ActiveRecord::FixtureSet.prepend FixtureSetExtension
  ActiveRecord::ConnectionAdapters::PostGISAdapter.prepend IntegrityExtension
end
