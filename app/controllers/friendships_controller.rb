class FriendshipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_friendship, only: [:update, :destroy]
  # GET /friendships
  # Permite filtrar por estado: /friendships?status=accepted o /friendships?status=pending
  def index
    if params[:status] == 'pending'
      render json: current_user.pending_requests
    else
      # Por defecto, o si status=accepted, devuelve los amigos confirmados.
      # Devuelve los registros de amistad aceptados.
      render json: current_user.accepted_friendships
    end
  end

  # POST /friendships
  def create
    # Usamos strong parameters para construir la amistad de forma segura.
    @friendship = current_user.friendships.build(friendship_params)

    if @friendship.save
      # --- Lógica de Notificación: Nueva solicitud de amistad ---
      notification = Notification.create(
        user: @friendship.friend, # El usuario que recibe la solicitud
        actor: current_user,      # El usuario que envía la solicitud
        action_type: :new_friendship_request,
        notifiable: @friendship
      )
      NotificationBroadcastJob.perform_later(notification) if notification.persisted?
      # --- Fin Lógica de Notificación ---
      render json: @friendship, status: :created
    else
      render json: { errors: @friendship.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /friendships/:id
  def update
    # Autorización: solo el receptor de la solicitud puede aceptarla.
    if @friendship.friend == current_user && @friendship.pending?
      @friendship.accepted!
      # --- Lógica de Notificación: Solicitud aceptada ---
      notification = Notification.create(
        user: @friendship.user,   # Notificar al usuario que envió la solicitud originalmente
        actor: current_user,      # El actor es quien acaba de aceptar
        action_type: :accepted_friendship,
        notifiable: @friendship
      )
      NotificationBroadcastJob.perform_later(notification) if notification.persisted?
      # --- Fin Lógica de Notificación ---
      render json: @friendship, status: :ok
    else
      render json: { error: 'Not authorized to perform this action' }, status: :unauthorized
    end
  end

  # DELETE /friendships/:id
  def destroy
    # Autorización: cualquiera de los dos usuarios en la amistad puede eliminarla.
    if @friendship.user == current_user || @friendship.friend == current_user
      @friendship.destroy
      head :no_content # Respuesta 204 No Content, estándar para un DELETE exitoso.
    else
      render json: { error: 'Not authorized to perform this action' }, status: :unauthorized
    end
  end

  # GET /friendships/status/:user_id
  # Verifica el estado de la amistad entre el usuario actual y otro usuario.
  def status
    user_a_id = current_user.id
    user_b_id = params[:user_id]

    # Es una buena práctica manejar el caso en que un usuario se busca a sí mismo.
    if user_a_id.to_s == user_b_id
      return render json: { error: 'Cannot check friendship status with yourself' }, status: :bad_request
    end

    friendship = Friendship.where(user_id: user_a_id, friend_id: user_b_id)
                           .or(Friendship.where(user_id: user_b_id, friend_id: user_a_id))
                           .first

    # Si se encuentra una amistad, la devuelve. Si no, devuelve 'null' con un estado 200 OK.
    render json: friendship, status: :ok
  end

  private

  def set_friendship
    @friendship = Friendship.find_by(id: params[:id])
    render json: { error: 'Friendship not found' }, status: :not_found unless @friendship
  end

  def friendship_params
    params.require(:friendship).permit(:friend_id)
  end
end
