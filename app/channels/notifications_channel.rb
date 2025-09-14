class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    # stream_for current_user crea un canal privado único para el usuario.
    # Ej: 'notifications:Z2lkOi8vZmFrZWJvb2stYmFja2VuZC9Vc2VyLzE'
    stream_for current_user
  end

  def unsubscribed
    # Cualquier limpieza necesaria cuando el canal se desuscribe
  end
end
