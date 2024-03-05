class E2ETask
  include Rake::DSL

  def initialize
    namespace :e2e do
      task setup: :environment do
        abort "Only works in e2e environment" unless Rails.env.e2e?

        unless ENV["SKIP_ASSETS_RESET"]
          Rake::Task["tmp:clear"].invoke
          Rake::Task["assets:clobber"].invoke
          Rake::Task["assets:precompile"].invoke
        end
        Rake::Task["db:reset"].invoke
        terminate_connections_to db_config["database"]
        drop_e2e_db_template
        create_e2e_db_template
      end

      task :db_reset do # rubocop:disable Rails/RakeEnvironment
        abort "Only works in e2e environment" unless Rails.env.e2e?

        terminate_connections_to db_config["database"]
        sh "#{pgpass} dropdb --if-exists #{connection_config} #{db_config["database"]}"
        sh "#{pgpass} createdb #{connection_config} --template=#{template_db_name} #{db_config["database"]}"
      end
    end
  end

  private

  def drop_e2e_db_template
    disable_template_sql = "ALTER DATABASE #{template_db_name} WITH IS_TEMPLATE false;"
    system "#{pgpass} psql -c \"#{disable_template_sql};\" #{connection_config}"
    sh "#{pgpass} dropdb --if-exists #{connection_config} #{template_db_name}"
  end

  def create_e2e_db_template
    set_template_sql = "ALTER DATABASE #{db_config["database"]} RENAME TO #{template_db_name}; ALTER DATABASE #{template_db_name} WITH IS_TEMPLATE true;"
    create_db_sql = "CREATE DATABASE #{db_config["database"]} WITH TEMPLATE #{template_db_name};"
    sh "#{pgpass} psql -c \"#{set_template_sql};\" #{connection_config}"
    sh "#{pgpass} psql -c \"#{create_db_sql};\" #{connection_config}"
  end

  def terminate_connections_to(database_name)
    system "#{pgpass} psql -c \"#{terminate_connection_sql(database_name)};\" #{connection_config} #{database_name}"
  end

  def terminate_connection_sql(database_name)
    "SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname = '#{database_name}' AND pid <> pg_backend_pid();"
  end

  def template_db_name
    "fti_e2e_template"
  end

  def connection_config
    "--host=#{db_config["host"]} --port=#{db_config["port"]} --username=#{db_config["username"]}"
  end

  def pgpass
    "PGPASSWORD=#{db_config["password"]}" if db_config["password"]
  end

  def db_config
    Rails.configuration.database_configuration[Rails.env]
  end
end

E2ETask.new
