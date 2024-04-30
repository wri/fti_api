class RemoveOrganizationFromObservers < ActiveRecord::Migration[7.1]
  class Observer < ApplicationRecord
    translates :organization
  end

  def up
    remove_column :observer_translations, :organization
  end

  def down
    Observer.add_translation_fields! organization: :string
  end
end
