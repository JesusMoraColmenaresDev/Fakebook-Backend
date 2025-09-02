class UsersController < ApplicationController
  # GET /users/:id
  def show
    @user = User.find(params[:id])
    render json: @user.as_json(only: [:id, :email, :name, :last_name, :birthday])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "User not found" }, status: :not_found
  end
  # GET /users
  def index
    render json: User.all.as_json(only: [:id, :name, :last_name])
  end  
end
