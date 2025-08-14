class ChangeUserLocaleToNotNull < ActiveRecord::Migration[7.2]
  class User < ApplicationRecord
  end

  def up
    User.where(locale: ["", nil]).update(locale: "en")

    change_column :users, :locale, :string, null: false, default: "en"
  end

  def down
    change_column :users, :locale, :string, null: true, default: nil
  end
end
