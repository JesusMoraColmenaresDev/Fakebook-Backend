class NotificationBroadcastJob < ApplicationJob
  queue_as :default

  def perform(notification)
    # 1. Construir el payload (el JSON que se enviará).
    #    Reutilizamos la misma estructura que en NotificationsController para consistencia.
    #    Precargamos las asociaciones necesarias para evitar N+1 queries.
    notification_with_data = Notification.includes(:actor, :notifiable).find(notification.id)

    notifiable_payload = {
      type: notification_with_data.notifiable_type,
      id: notification_with_data.notifiable_id
    }

    # Si la notificación es sobre un comentario, incluimos la información de su "padre".
    if notification_with_data.notifiable_type == 'Comment' && notification_with_data.notifiable.present?
      comment = notification_with_data.notifiable
      notifiable_payload[:commentable] = {
        type: comment.commentable_type,
        id: comment.commentable_id
      }
    end

    payload = {
      id: notification_with_data.id,
      actor: {
        id: notification_with_data.actor.id,
        name: notification_with_data.actor.name,
        last_name: notification_with_data.actor.last_name
      },
      action_type: notification_with_data.action_type,
      read: notification_with_data.read,
      created_at: notification_with_data.created_at,
      notifiable: notifiable_payload
    }

    # 2. Hacer el broadcast al canal privado del usuario que debe recibir la notificación.
    NotificationsChannel.broadcast_to(notification_with_data.user, payload)
  end
end
