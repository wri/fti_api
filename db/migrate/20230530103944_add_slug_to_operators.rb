class AddSlugToOperators < ActiveRecord::Migration[7.0]
  def change
    add_column :operators, :slug, :string
    add_index :operators, :slug, unique: true

    reversible do |dir|
      dir.up do
        PaperTrail.request.disable_model(Operator)
        Operator.find_each do |operator|
          operator.set_slug
          operator.save!
        end
        PaperTrail.request.enable_model(Operator)
      end
    end
  end
end
