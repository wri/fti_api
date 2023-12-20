class AddUnknownOperator < ActiveRecord::Migration[7.0]
  def up
    Operator.find_or_create_by!(name: "Unknown", operator_type: "Unknown", slug: "unknown")
  end

  def down
    Operator.where(slug: "unknown").destroy_all
  end
end
