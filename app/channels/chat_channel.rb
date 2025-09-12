class ChatChannel < ApplicationCable::Channel
  # Se llama cuando un cliente (frontend) intenta suscribirse a este canal.
  def subscribed
    # params[:conversation_id] vendrá desde el frontend.
    @conversation = Conversation.find_by(id: params[:conversation_id])

    # Si la conversación existe y el usuario actual es parte de ella, se suscribe.
    if @conversation && (@conversation.sender_id == current_user.id || @conversation.receiver_id == current_user.id)
      # 'stream_for @conversation' es la magia.
      # Le dice a Rails: "Cualquier cosa que se transmita para esta conversación,
      # envíasela a este cliente".
      stream_for @conversation
    else
      # Si no está autorizado, se rechaza la suscripción.
      reject
    end
  end

  # Se llama cuando el cliente envía un mensaje al servidor a través del WebSocket.
  # El frontend llamará a la función 'speak'.
  def speak(data)
    # Crea el mensaje en la base de datos, asociándolo a la conversación y al usuario actual.
    message = @conversation.messages.create!(content: data['message'], user: current_user)

    # Ahora, retransmite (broadcast) el mensaje a todos los que estén
    # escuchando en este stream. Usamos la misma serialización que en la API.
    ChatChannel.broadcast_to(@conversation, message.as_json(include: { user: { only: [:id, :name, :last_name] } }))
  end

  # Se llama cuando un cliente se desconecta.
  def unsubscribed
    # Aquí podrías poner lógica de limpieza si fuera necesario, como actualizar el estado "en línea".
  end
end
