class AddPersonalInformationToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :name, :string
    add_column :users, :last_name, :string
    add_column :users, :birthday, :date
  end

  def down
    remove_column :users, :name, :string
    remove_column :users, :last_name, :string
    remove_column :users, :birthday, :date
  end
end
