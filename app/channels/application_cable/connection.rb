module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # Identificamos la conexión por el usuario actual.
    # Esto nos dará acceso a `current_user` en los Canales.
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # El frontend enviará el token JWT como un parámetro en la URL de conexión.
      # ej: ws://localhost:3000/cable?token=MI_TOKEN_JWT
      token = request.params[:token]
      
      # Usamos el decodificador de devise-jwt para encontrar al usuario de forma segura.
      user = Warden::JWTAuth::UserDecoder.new.call(token, :user, nil)

      # Si el decodificador encontró un usuario, lo aceptamos. Si no, rechazamos la conexión.
      user || reject_unauthorized_connection
    end
  end
end
