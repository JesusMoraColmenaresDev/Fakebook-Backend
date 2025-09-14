class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true # esto indica que puede tener una relacion polymorfica , ya sea post o share

  # Un comentario puede tener notificaciones (ej: cuando alguien responde a tu comentario).
  has_many :notifications, as: :notifiable, dependent: :destroy
end
