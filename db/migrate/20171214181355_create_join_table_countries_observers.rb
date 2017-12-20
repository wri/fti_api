class CreateJoinTableCountriesObservers < ActiveRecord::Migration[5.0]
  def up
    create_join_table :countries, :observers do |t|
      t.index [:country_id, :observer_id]
      t.index [:observer_id, :country_id]
    end

    add_index(:countries_observers, [:country_id, :observer_id], unique: true, name: 'index_unique_country_observer' )

    Observer.find_each do |observer|
      observer.countries << Country.find(observer.country_id) if observer.country_id.present?
    end

    remove_index :observers, :country_id
    remove_column :observers, :country_id
  end

  def down
    add_column :observers, :country_id, :integer
    add_index :observers, :country_id

    Observer.find_each do |observer|
      observer.country_id = observer.countries.first
      observer.save!
    end

    drop_join_table :countries, :observers
  end
end
