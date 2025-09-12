class CreateConversationsAndMessages < ActiveRecord::Migration[8.0]
  def change
    # Tabla para las conversaciones
    create_table :conversations do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :receiver, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    # Agrega un índice para asegurar que el par (sender_id, receiver_id) sea único.
    add_index :conversations, [:sender_id, :receiver_id], unique: true

    # Tabla para los mensajes
    create_table :messages do |t|
      t.text :content, null: false
      t.references :conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true # El autor del mensaje
      t.timestamps
    end
  end
end
