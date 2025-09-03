class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  # Solicitudes de amistad que este usuario ha enviado
  has_many :sent_friend_requests,
           foreign_key: :user_id,
           class_name: 'Friendship',
           dependent: :destroy

  # Solicitudes de amistad que este usuario ha recibido
  has_many :received_friend_requests,
           foreign_key: :friend_id,
           class_name: 'Friendship',
           dependent: :destroy

  # Método para obtener una lista de todos los amigos (amistades aceptadas)
  def friends
    #con el pluck solo obtendria los id de los registros qeu cumplen con la condicion del where 
    sent_friend_ids = Friendship.where(user_id: id, status: :accepted).pluck(:friend_id)
    received_friend_ids = Friendship.where(friend_id: id, status: :accepted).pluck(:user_id)
    User.where(id: sent_friend_ids + received_friend_ids)
  end
end
