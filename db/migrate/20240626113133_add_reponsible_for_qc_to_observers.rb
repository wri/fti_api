class AddReponsibleForQCToObservers < ActiveRecord::Migration[7.1]
  class User < ApplicationRecord
  end

  class Observer < ApplicationRecord
    belongs_to :responsible_admin, class_name: "User", optional: true
    belongs_to :responsible_qc1, class_name: "User", optional: true
    belongs_to :responsible_qc2, class_name: "User", optional: true
  end

  def change
    add_reference :observers, :responsible_qc1, index: true, foreign_key: {to_table: :users, on_delete: :nullify}
    add_reference :observers, :responsible_qc2, index: true, foreign_key: {to_table: :users, on_delete: :nullify}

    reversible do |dir|
      dir.up do
        Observer.find_each do |observer|
          next if observer.responsible_admin.nil?

          observer.update!(responsible_qc2: observer.responsible_admin)
        end
      end
    end
  end
end
