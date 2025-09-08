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
      render json: @post, status: :created
    else
      render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /posts/:id
  def update
    # Verificamos que el usuario actual sea el autor del post.
    if @post.user == current_user
      if @post.update(post_params)
        # Si la actualización es exitosa, devolvemos el post actualizado.
        render json: @post, include: { user: { only: [:id, :name, :last_name] } }
      else
        # Si hay errores de validación, los mostramos.
        render json: { errors: @post.errors.full_messages }, status: :unprocessable_entity
      end
    else
      # Si el usuario no es el autor, devolvemos un error de autorización.
      render json: { error: 'Not authorized' }, status: :unauthorized
    end
  end

  # DELETE /posts/:id
  def destroy
    # Verificamos que el usuario actual sea el autor del post.
    if @post.user == current_user
      @post.destroy
      # Respondemos con 204 No Content, el estándar para un DELETE exitoso.
      head :no_content
    else
      render json: { error: 'Not authorized' }, status: :unauthorized
    end
  end

  private

  def set_post
    @post = Post.find_by(id: params[:id])
    # Si el post no se encuentra, devolvemos un error 404.
    render json: { error: 'Post not found' }, status: :not_found unless @post
  end

  def post_params
    # No es necesario permitir :user_id, ya que lo obtenemos de current_user.
    params.require(:post).permit(:content, :post_picture)
  end
end
