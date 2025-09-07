class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post, only: [:show, :update, :destroy]

  # GET /posts (para el feed de noticias)
  # GET /posts?user_id=:id (para los posts de un usuario específico)
  def index
    if params[:user_id]
      # Si se pasa un user_id, muestra solo los posts de ese usuario.
      user = User.find(params[:user_id])
      @posts = user.posts.order(created_at: :desc)
    else
      # Si no, muestra el "feed": posts del usuario actual y sus amigos.
      friend_ids = current_user.friends.pluck(:id)
      user_and_friend_ids = friend_ids + [current_user.id]
      @posts = Post.where(user_id: user_and_friend_ids).order(created_at: :desc)
    end

    # Incluimos la información del autor en cada post para mostrarla en el frontend.
    render json: @posts, include: { user: { only: [:id, :name, :last_name] } }
  end

  # GET /posts/:id
  def show
    render json: @post, include: { user: { only: [:id, :name, :last_name] } }
  end

  # POST /posts
  def create
    # Usamos current_user.posts.build para asociar el post automáticamente.
    @post = current_user.posts.build(post_params)
    if @post.save
      render json: @post, status: :created, location: @post
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
  end

  def destroy
  end

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    # No es necesario permitir :user_id, ya que lo obtenemos de current_user.
    params.require(:post).permit(:content, :post_picture)
  end
  
end
