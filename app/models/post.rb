class Post < ApplicationRecord
  belongs_to :user
  has_many :shares, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  # Un post puede tener muchas notificaciones (ej: cuando alguien lo comenta o comparte).
  has_many :notifications, as: :notifiable, dependent: :destroy
end
