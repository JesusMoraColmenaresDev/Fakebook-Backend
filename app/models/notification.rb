class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: 'User'
  belongs_to :notifiable, polymorphic: true

  # Scope para encontrar fácilmente las notificaciones no leídas.
  scope :unread, -> { where(read: false) }

  # Enum para que los tipos de acción sean legibles en el código.
  # Esto nos permite hacer `notification.new_comment?` en lugar de `notification.action_type == 0`.
  enum :action_type, {
    new_comment: 0,
    new_share: 1,
    new_friendship_request: 2,
    accepted_friendship: 3
  }

end
