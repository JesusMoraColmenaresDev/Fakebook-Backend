class FriendshipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_friendship, only: [:update, :destroy]

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # GET /friendships
  # Devuelve las solicitudes de amistad pendientes que ha recibido el usuario actual.
  def index
    @pending_requests = current_user.received_friend_requests.pending
    render json: @pending_requests, include: { user: { only: [:id, :name, :last_name] } }
  end

  # POST /friendships
  # Crea una nueva solicitud de amistad.
  def create
    # Previene que un usuario se envíe una solicitud a sí mismo.
    if current_user.id == params[:friend_id].to_i
      return render json: { error: "You cannot send a friend request to yourself." }, status: :unprocessable_entity
    end

    @friendship = current_user.sent_friend_requests.build(friend_id: params[:friend_id])

    if @friendship.save
      render json: @friendship, status: :created
    else
      render json: { errors: @friendship.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /friendships/:id
  # Acepta o rechaza una solicitud de amistad.
  def update
    # Solo se pueden actualizar las solicitudes recibidas.
    if @friendship.friend == current_user && @friendship.update(friendship_params)
      render json: @friendship
    else
      render json: { error: "Unable to update friendship status." }, status: :unprocessable_entity
    end
  end

  # DELETE /friendships/:id
  # Cancela una solicitud enviada o elimina una amistad existente.
  def destroy
    # Un usuario solo puede eliminar una amistad si es el que la envió o el que la recibió.
    if @friendship.user == current_user || @friendship.friend == current_user
      @friendship.destroy
      head :no_content
    else
      render json: { error: "You are not authorized to perform this action." }, status: :unauthorized
    end
  end

  private

  def set_friendship
    @friendship = Friendship.find(params[:id])
  end

  def friendship_params
    # 1. Requiere el objeto 'friendship' y permite solo el atributo 'status'.
    permitted = params.require(:friendship).permit(:status)

    # 2. Valida que el status sea uno de los permitidos para esta acción.
    # El enum de Rails manejará la conversión de "accepted" a 1 automáticamente.
    unless ['accepted', 'rejected'].include?(permitted[:status])
      permitted.delete(:status) # Elimina el status si no es válido.
    end
    permitted
  end

  def record_not_found
    render json: { error: "Friendship not found" }, status: :not_found
  end
end
