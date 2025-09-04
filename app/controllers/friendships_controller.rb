class FriendshipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_friendship, only: [:update, :destroy]
  # GET /friendships
  # Permite filtrar por estado: /friendships?status=accepted o /friendships?status=pending
  def index
    if params[:status] == 'pending'
      @pending_requests = current_user.pending_requests
      render json: @pending_requests
    else
      # Por defecto, o si status=accepted, devuelve los amigos confirmados.
      @friends = current_user.friends
      render json: @friends
    end
  end

  # POST /friendships
  def create
    # Usamos strong parameters para construir la amistad de forma segura.
    @friendship = current_user.friendships.build(friendship_params)

    if @friendship.save
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
