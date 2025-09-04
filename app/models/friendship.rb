class Friendship < ApplicationRecord
  # --- ASOCIACIONES ---
  # 'user' es quien envía la solicitud. Rails lo entiende automáticamente.
  belongs_to :user
  # 'friend' es quien recibe la solicitud. Debemos decirle a Rails que 'friend'
  # también es un objeto de la clase 'User'.
  belongs_to :friend, class_name: 'User'

  # --- ENUM ---
  # Define los estados posibles para la amistad.
  # :pending se guardará como 0 en la base de datos.
  # :accepted se guardará como 1.
  # Esto nos da métodos útiles como `friendship.pending?` o `friendship.accepted!`.
  enum :status, { pending: 0, accepted: 1 }

  # --- VALIDACIONES ---
  # 1. Evita que un usuario se envíe una solicitud a sí mismo.
  validate :prevent_self_friending

  # 2. Evita que se cree una solicitud si ya existe una en la dirección opuesta.
  #    Ej: Si ya existe (user: 1, friend: 2), no se puede crear (user: 2, friend: 1).
  validate :prevent_inverse_friendship, on: :create

  private 

  def prevent_self_friending
    errors.add(:friend, "can't be the same as the user") if user_id == friend_id
  end

  def prevent_inverse_friendship
    if Friendship.exists?(user_id: friend_id, friend_id: user_id)
      errors.add(:base, 'A friendship or request already exists between these users.')
    end
  end
end
