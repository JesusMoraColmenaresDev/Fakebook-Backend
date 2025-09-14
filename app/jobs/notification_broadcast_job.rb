class NotificationBroadcastJob < ApplicationJob
  queue_as :default

  def perform(notification)
    # 1. Construir el payload (el JSON que se enviará).
    #    Reutilizamos la misma estructura que en NotificationsController para consistencia.
    #    Precargamos el actor para evitar una consulta extra.
    notification_with_actor = Notification.includes(:actor).find(notification.id)

    payload = {
      id: notification_with_actor.id,
      actor: {
        id: notification_with_actor.actor.id,
        name: notification_with_actor.actor.name,
        last_name: notification_with_actor.actor.last_name
      },
      action_type: notification_with_actor.action_type,
      read: notification_with_actor.read,
      created_at: notification_with_actor.created_at,
      notifiable: { type: notification_with_actor.notifiable_type, id: notification_with_actor.notifiable_id }
    }

    # 2. Hacer el broadcast al canal privado del usuario que debe recibir la notificación.
    NotificationsChannel.broadcast_to(notification_with_actor.user, payload)
  end
end
