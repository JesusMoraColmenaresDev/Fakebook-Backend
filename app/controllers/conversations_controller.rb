class ConversationsController < ApplicationController
  before_action :authenticate_user!

  # GET /conversations
  # Devuelve todas las conversaciones del usuario actual.
  def index
    conversations = current_user.conversations.includes(:sender, :receiver).order(updated_at: :desc)

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
        # 'updated_at' es útil para ordenar los chats por el más reciente.
        updated_at: convo.updated_at
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
