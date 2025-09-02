class CurrentUserController < ApplicationController
  before_action :authenticate_user!

  def index
    render json: {
      data: current_user.as_json(only: [:id, :email, :name, :last_name, :birthday])
    }, status: :ok
  end
end