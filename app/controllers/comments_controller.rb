class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_commentable

  # GET /posts/:post_id/comments
  # GET /shares/:share_id/comments
  def index
    @comments = @commentable.comments.includes(:user).order(created_at: :asc)
    render json: @comments, include: { user: { only: [:id, :name, :last_name] } }
  end

  # POST /posts/:post_id/comments
  # POST /shares/:share_id/comments
  def create
    # Construimos el comentario a través de la asociación del objeto "commentable"
    @comment = @commentable.comments.build(comment_params)
    # Asignamos el usuario actual al comentario
    @comment.user = current_user

    if @comment.save
      # --- Lógica de Notificación ---
      # El dueño del post/share que se está comentando
      owner = @commentable.user
      # El usuario que está comentando
      actor = current_user

      # Solo notificar si el que comenta no es el dueño del contenido
      if owner != actor
        notification = Notification.create(
          user: owner,
          actor: actor,
          action_type: :new_comment,
          notifiable: @comment
        )
        # Encolamos el job para que se ejecute en segundo plano si la notificación se guardó.
        NotificationBroadcastJob.perform_later(notification) if notification.persisted?
      end
      # --- Fin Lógica de Notificación ---
      render json: @comment, include: { user: { only: [:id, :name, :last_name] } }, status: :created
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_commentable
    if params[:post_id]
      @commentable = Post.find(params[:post_id])
    elsif params[:share_id]
      @commentable = Share.find(params[:share_id])
    end
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
