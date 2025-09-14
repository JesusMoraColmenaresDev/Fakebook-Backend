class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: %i[ update ]

  # GET /notifications
  def index
    # Precargamos 'actor' y 'notifiable' para evitar N+1 queries al serializar.
    @notifications = current_user.notifications.includes(:actor, :notifiable).order(created_at: :desc)

    # Reutilizamos el helper de serialización para mantener la consistencia.
    render json: @notifications.map(&method(:serialize_notification))
  end

  # POST /notifications
  # (No implementaremos 'create' directamente, se crearán desde otros controladores)

  # PATCH/PUT /notifications/1
  def update
    if @notification.update(notification_params)
      # Devolver la notificación actualizada con la misma estructura que el index.
      render json: serialize_notification(@notification)
    else
      render json: @notification.errors, status: :unprocessable_entity
    end
  end

  # PATCH /notifications/mark_all_as_read
  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true)
    head :no_content
  end

  # DELETE /notifications/1
  # (No implementaremos 'destroy' por ahora)

  private
    def set_notification
      # Asegurarnos que el usuario solo pueda modificar sus propias notificaciones.
      @notification = current_user.notifications.includes(:actor, :notifiable).find(params[:id])
    end

    def notification_params
      # Solo permitimos que se actualice el estado 'read'
      params.require(:notification).permit(:read)
    end

     # Helper para mantener la consistencia en la respuesta JSON.
    def serialize_notification(notification)
      notifiable_payload = {
        type: notification.notifiable_type,
        id: notification.notifiable_id
      }

      # Si la notificación es sobre un comentario, incluimos la información de su "padre"
      # para que el frontend pueda construir el enlace correcto sin hacer otra llamada a la API.
      if notification.notifiable_type == 'Comment' && notification.notifiable.present?
        comment = notification.notifiable
        notifiable_payload[:commentable] = {
          type: comment.commentable_type, # Será 'Post' o 'Share'
          id: comment.commentable_id
        }
      end

      {
        id: notification.id,
        actor: {
          id: notification.actor.id,
          name: notification.actor.name,
          last_name: notification.actor.last_name
        },
        action_type: notification.action_type,
        read: notification.read,
        created_at: notification.created_at,
        notifiable: notifiable_payload
      }
    end
end
