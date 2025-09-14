class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: %i[ update ]

  # GET /notifications
  def index
    # Precargamos el 'actor' para evitar N+1 queries.
    @notifications = current_user.notifications.includes(:actor).order(created_at: :desc)

    # Mapeamos la respuesta para que sea más útil para el frontend.
    render json: @notifications.map { |notification|
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
        notifiable: { type: notification.notifiable_type, id: notification.notifiable_id }
      }
    }
  end

  # POST /notifications
  # (No implementaremos 'create' directamente, se crearán desde otros controladores)

  # PATCH/PUT /notifications/1
  def update
    if @notification.update(notification_params)
      render json: @notification
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
      # Asegurarnos que el usuario solo pueda modificar sus propias notificaciones
      @notification = current_user.notifications.find(params[:id])
    end

    def notification_params
      # Solo permitimos que se actualice el estado 'read'
      params.require(:notification).permit(:read)
    end
end
