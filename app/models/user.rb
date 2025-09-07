class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  # --- ASOCIACIONES DE AMISTAD ---

  # Solicitudes de amistad que este usuario ha enviado.
  # Si se elimina el usuario, también se eliminan estas solicitudes.
  has_many :friendships, dependent: :destroy

  # Solicitudes de amistad que este usuario ha recibido.
  # Se necesita especificar la clase y la clave foránea porque Rails no puede adivinarlo.
  has_many :inverse_friendships, class_name: 'Friendship', foreign_key: 'friend_id', dependent: :destroy

  # Un usuario puede tener muchas publicaciones. Si se elimina el usuario, se eliminan sus publicaciones.
  has_many :posts, dependent: :destroy

  # --- MÉTODOS DE AYUDA ---

  # Devuelve una lista de todos los amigos confirmados.
  def friends
    friends_i_sent_request_to = Friendship.where(user_id: id, status: :accepted).pluck(:friend_id)
    friends_i_received_request_from = Friendship.where(friend_id: id, status: :accepted).pluck(:user_id)

    friend_ids = friends_i_sent_request_to + friends_i_received_request_from
    User.where(id: friend_ids)
  end

  # Devuelve los registros de amistad aceptados donde el usuario está involucrado.
  def accepted_friendships
    Friendship.where(status: :accepted)
              .where("user_id = :id OR friend_id = :id", id: id)
  end

  # Devuelve una lista de usuarios que han enviado una solicitud pendiente a este usuario.
  def pending_requests
    inverse_friendships.pending
  end
end
