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

    # --- LÓGICA DE NOTIFICACIÓN AÑADIDA ---
    # 1. Identificar al otro usuario en la conversación.
    other_user = @conversation.sender_id == current_user.id ? @conversation.receiver : @conversation.sender

    # 2. Forzar la actualización de 'updated_at' en la conversación para que aparezca primero en la lista.
    @conversation.touch

    # 3. Preparar el payload para el otro usuario, replicando la estructura del ConversationsController.
    #    El 'unread_count' se calcula desde la perspectiva del 'other_user'.
    payload = {
      id: @conversation.id,
      other_user: { id: current_user.id, name: current_user.name, last_name: current_user.last_name },
      last_message: message.as_json(only: [:content, :created_at, :user_id]),
      unread_count: @conversation.messages.where.not(user_id: other_user.id).where(read: false).count,
      updated_at: @conversation.updated_at
    }

    # 4. Transmitir el payload al canal privado del otro usuario.
    #    El servidor actúa como cartero, entregando la notificación al buzón correcto.
    UserChannel.broadcast_to(other_user, payload)
  end

  # Se llama cuando un cliente se desconecta.
  def unsubscribed
    # Aquí podrías poner lógica de limpieza si fuera necesario, como actualizar el estado "en línea".
  end
end
