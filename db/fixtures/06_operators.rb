Rake::Task["import:operators"].invoke unless Operator.any?
Operator.find_or_create_by!(name: "Unknown", operator_type: "Unknown", slug: "unknown")
