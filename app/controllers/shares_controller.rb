class SharesController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def create
    # Construimos el 'share' a través del usuario actual para asignar user_id automáticamente.
    # El post_id se asigna a través de los strong parameters (share_params).
    @share = current_user.shares.build(share_params)

    if @share.save
      # Devolvemos el 'share' creado, incluyendo la información del post y del usuario.
      render json: @share, include: {
        # Incluimos el post que se compartió.
        post: {
          only: [:id, :content, :post_picture],
          # Y dentro del post, incluimos a su autor original. ¡Aquí está la magia!
          include: { user: { only: [:id, :name, :last_name] } }
        },
        # También incluimos al usuario que realizó el 'share'.
        user: { only: [:id, :name, :last_name] }
      }, status: :created
    else
      render json: { errors: @share.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private
  def share_params # Permitimos que el post_id venga en el cuerpo de la petición.
    params.require(:share).permit(:content, :post_id)
  end
end
