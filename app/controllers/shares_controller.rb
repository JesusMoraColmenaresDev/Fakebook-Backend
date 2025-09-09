class SharesController < ApplicationController
  before_action :authenticate_user!

  # GET /shares (para el feed de shares)
  # GET /shares?user_id=:id (para los shares de un usuario específico)
  def index
    if params[:user_id]
      # Si se pasa un user_id, muestra solo los shares de ese usuario.
      user = User.find_by(id: params[:user_id])
      return render json: { error: 'User not found' }, status: :not_found unless user

      @shares = user.shares.includes(post: :user, user: {}).order(created_at: :desc)
    else
      # Si no, muestra el "feed": shares del usuario actual y sus amigos.
      friend_ids = current_user.friends.pluck(:id)
      user_and_friend_ids = friend_ids + [current_user.id]
      @shares = Share.where(user_id: user_and_friend_ids).includes(post: :user, user: {}).order(created_at: :desc)
    end
    render json: @shares.as_json(json_options)
  end

  def create
    # Construimos el 'share' a través del usuario actual para asignar user_id automáticamente.
    # El post_id se asigna a través de los strong parameters (share_params).
    @share = current_user.shares.build(share_params)

    if @share.save
      # Devolvemos el 'share' creado, incluyendo la información del post y del usuario.
      render json: @share.as_json(json_options), status: :created
    else
      render json: { errors: @share.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def share_params # Permitimos que el post_id venga en el cuerpo de la petición.
    params.require(:share).permit(:content, :post_id)
  end

  # Método privado para centralizar las opciones de serialización JSON.
  def json_options
    {
      only: [:id, :content],
      include: {
        # Incluimos el post que se compartió y su autor original.
        post: { only: [:id, :content, :post_picture], include: { user: { only: [:id, :name, :last_name] } } },
        # También incluimos al usuario que realizó el 'share'.
        user: { only: [:id, :name, :last_name] }
      }
    }
  end
end
