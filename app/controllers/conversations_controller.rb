class ConversationsController < ApplicationController
  before_action :authenticate_user!

  # GET /conversations
  # Devuelve todas las conversaciones del usuario actual.
  def index
    # Construimos una subconsulta para contar los mensajes no leídos para el usuario actual en cada conversación.
    # Esto es muy eficiente y evita problemas de N+1.
    unread_count_subquery = Message.select('COUNT(*)')
                                   .where('messages.conversation_id = conversations.id')
                                   .where(read: false)
                                   .where.not(user_id: current_user.id)
                                   .to_sql

    # Obtenemos las conversaciones, incluyendo el conteo de no leídos como un campo virtual 'unread_count'.
    # También precargamos las asociaciones necesarias.
    conversations = current_user.conversations
                                .select("conversations.*, (#{unread_count_subquery}) AS unread_count")
                                .includes(:sender, :receiver, :last_message)
                                .order(updated_at: :desc)

    # Serializamos la respuesta para que el frontend sepa quién es el "otro" usuario en el chat.
    render json: conversations.map { |convo|
      other_user = (convo.sender == current_user) ? convo.receiver : convo.sender
      {
        id: convo.id,
        other_user: {
          id: other_user.id,
          name: other_user.name,
          last_name: other_user.last_name
        },
        # Usamos la asociación precargada. El `&.` (safe navigation) evita errores si no hay mensajes.
        last_message: convo.last_message&.as_json(only: [:content, :created_at, :user_id]),
        # Incluimos el conteo de mensajes no leídos. `to_i` para asegurar que sea un número.
        unread_count: convo.try(:unread_count).to_i,
        # 'updated_at' es útil para ordenar los chats por el más reciente.
        updated_at: convo.updated_at # Se refiere al updated_at de la conversación
      }
    }
  end

  # POST /conversations
  # Busca o crea una conversación con otro usuario.
  def create
    receiver_id = params[:receiver_id]
    conversation = Conversation.between(current_user.id, receiver_id)

    if conversation.present?
      render json: conversation, status: :ok
    else
      @conversation = Conversation.new(sender_id: current_user.id, receiver_id: receiver_id)
      if @conversation.save
        render json: @conversation, status: :created
      else
        render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
