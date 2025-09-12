class Message < ApplicationRecord
  # Un mensaje pertenece a una conversación y a un usuario (quien lo envió).
  belongs_to :conversation
  belongs_to :user

  # El contenido del mensaje no puede estar vacío.
  validates :content, presence: true
end
