class AddReadToMessages < ActiveRecord::Migration[8.0]
  def change
    # Agrega la columna 'read' a la tabla de mensajes.
    # Por defecto, un mensaje no está leído (false).
    # null: false asegura que siempre tengamos un valor booleano.
    add_column :messages, :read, :boolean, default: false, null: false
  end
end