class AddMissionTypeToObservationReport < ActiveRecord::Migration[7.2]
  def up
    add_column :observation_reports, :mission_type, :integer
  end

  def down
    remove_column :observation_reports, :mission_type
  end
end
