class MessagesController < ApplicationController
  before_action :authenticate_user!

  # GET /conversations/:conversation_id/messages
  # Devuelve todos los mensajes de una conversación específica.
  def index
    conversation = Conversation.find(params[:conversation_id])

    # Autorización: Asegurarse de que el usuario actual es parte de la conversación.
    unless conversation.sender_id == current_user.id || conversation.receiver_id == current_user.id
      return render json: { error: "Not authorized to view this conversation" }, status: :unauthorized
    end

    # Marcar como leídos todos los mensajes de esta conversación que no fueron enviados por el usuario actual.
    conversation.messages.where.not(user_id: current_user.id).update_all(read: true)

    # Devolvemos los mensajes en orden cronológico, incluyendo la información del autor.
    messages = conversation.messages.order(created_at: :asc).includes(:user)
    render json: messages, include: { user: { only: [:id, :name, :last_name] } }
  end
end
