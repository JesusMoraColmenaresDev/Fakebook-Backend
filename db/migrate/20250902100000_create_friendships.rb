class CreateFriendships < ActiveRecord::Migration[8.0]
  def change
    create_table :friendships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :friend, null: false, foreign_key: { to_table: :users }
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    # Esto asegura que no se pueda enviar una solicitud de amistad dos veces a la misma persona.
    add_index :friendships, [:user_id, :friend_id], unique: true
  end
end
