class FeedsController < ApplicationController
  before_action :authenticate_user!

  # GET /feed
  # NOTA: Esta versión obtiene todos los items. Para aplicaciones grandes,
  # se recomienda implementar paginación para mejorar el rendimiento.
  # GET /feed?user_id=:id (para el feed de un usuario específico)
  def index
    # 1. Determinar para qué usuarios se debe construir el feed.
    if params[:user_id]
      # Si se pasa un user_id, el feed es solo para ese usuario.
      user = User.find_by(id: params[:user_id])
      return render json: { error: 'User not found' }, status: :not_found unless user
      user_and_friend_ids = [user.id]
    else
      # Si no, el feed es para el usuario actual y sus amigos.
      friend_ids = current_user.friends.pluck(:id)
      user_and_friend_ids = friend_ids + [current_user.id]
    end

    # 2. Obtener todos los posts y shares relevantes, incluyendo sus asociaciones.
    posts = Post.where(user_id: user_and_friend_ids)
                .includes(:user)

    shares = Share.where(user_id: user_and_friend_ids)
                  .includes(post: :user, user: {})

    # 3. Mapear ambos a una estructura común para poder combinarlos.
    post_items = posts.map { |post| { type: 'post', created_at: post.created_at, item: post } }
    share_items = shares.map { |share| { type: 'share', created_at: share.created_at, item: share } }

    # 4. Combinar los dos arrays, ordenarlos por fecha de creación (más nuevos primero).
    feed_items = (post_items + share_items)
                 .sort_by { |item| item[:created_at] }
                 .reverse

    # 5. Renderizar el resultado final, usando un método helper para serializar cada item.
    render json: feed_items.map { |feed_item|
      {
        type: feed_item[:type],
        created_at: feed_item[:created_at],
        data: serialize_item(feed_item[:item])
      }
    }
  end

  private

  # Decide qué método de serialización usar según la clase del objeto.
  def serialize_item(item)
    case item
    when Post
      item.as_json(only: [:id, :content, :user_id, :post_picture], include: { user: { only: [:id, :name, :last_name] } })
    when Share
      item.as_json(
        only: [:id, :content],
        include: {
          post: { only: [:id, :content, :user_id, :post_picture], include: { user: { only: [:id, :name, :last_name] } } },
          user: { only: [:id, :name, :last_name] }
        }
      )
    end
  end
end
