class Conversation < ApplicationRecord
  # --- ASOCIACIONES ---
  # Una conversación ocurre entre dos usuarios. Los llamaremos sender y receiver.
  belongs_to :sender, class_name: 'User'
  belongs_to :receiver, class_name: 'User'

  # Una conversación tiene muchos mensajes. Si se borra la conversación, se borran los mensajes.
  has_many :messages, dependent: :destroy

  # Asociación para obtener directamente el último mensaje de la conversación.
  has_one :last_message, -> { order(created_at: :desc) }, class_name: 'Message'

  # --- VALIDACIONES ---
  # 1. Evita que un usuario inicie una conversación consigo mismo.
  validate :prevent_self_conversation

  # 2. Asegura que la combinación sender/receiver sea única.
  validates :sender_id, uniqueness: { scope: :receiver_id }

  # 3. Evita que se cree una conversación si ya existe una en la dirección opuesta.
  validate -> { errors.add(:base, 'A conversation already exists between these users.') if Conversation.exists?(sender_id: receiver_id, receiver_id: sender_id) }, on: :create

  # --- MÉTODOS DE CLASE ---
  # Encuentra una conversación entre dos usuarios, sin importar el orden.
  def self.between(user1_id, user2_id)
    where(
      "(sender_id = :user1_id AND receiver_id = :user2_id) OR (sender_id = :user2_id AND receiver_id = :user1_id)",
      user1_id: user1_id,
      user2_id: user2_id
    ).first
  end


  private

  def prevent_self_conversation
    errors.add(:receiver, "can't be the same as the sender") if sender_id == receiver_id
  end
end
