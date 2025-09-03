class Friendship < ApplicationRecord
  # Define las asociaciones. Ambas apuntan al modelo User.
  belongs_to :user
  belongs_to :friend, class_name: 'User'

  # Define los estados posibles para una amistad.
  # :pending es el valor por defecto (0).
  enum status: { pending: 0, accepted: 1, rejected: 2, blocked: 3 }

  # Validación para asegurar que la combinación de user y friend sea única.
  validates :user_id, uniqueness: { scope: :friend_id, message: "Friend request already sent." }

  # Validación para prevenir que se cree una solicitud si ya existe una en la dirección opuesta.
  validate :prevent_duplicate_friendship

  private

  def prevent_duplicate_friendship
    errors.add(:base, "A friendship request already exists between these users.") if Friendship.exists?(user_id: friend_id, friend_id: user_id)
  end
end
