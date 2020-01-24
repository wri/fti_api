# https://stackoverflow.com/questions/40882420/rails-postgis-error-cannot-drop-table-spatial-ref-sys
::ActiveRecord::SchemaDumper.ignore_tables |=
  %w[layer spatial_ref_sys topology us_gaz us_lex us_rules]
