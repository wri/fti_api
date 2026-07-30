# frozen_string_literal: true

# public tables owned by extensions, dumping them makes schema load fail on drop
# tiger and topology schemas are already excluded by schema_search_path in database.yml
::ActiveRecord::SchemaDumper.ignore_tables |= %w[spatial_ref_sys us_gaz us_lex us_rules]
