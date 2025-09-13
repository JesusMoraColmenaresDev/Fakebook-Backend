class UserChannel < ApplicationCable::Channel
  # Se llama cuando un cliente (frontend) se suscribe a su canal de notificaciones personal.
  def subscribed
    # 'stream_for current_user' crea un stream privado y único para el usuario conectado.
    # Por ejemplo: "user_channel_Z2lkOi8vZmFrZWJvb2stYmFja2VuZC9Vc2VyLzE" para el usuario con ID 1.
    # Action Cable se encarga de generar y gestionar estos nombres de stream de forma segura.
    stream_for current_user
  end

  def unsubscribed; end
end
