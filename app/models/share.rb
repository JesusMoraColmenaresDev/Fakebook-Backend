class Share < ApplicationRecord
  belongs_to :user
  belongs_to :post
  has_many :comments, as: :commentable, dependent: :destroy

  # Un share puede tener notificaciones (ej: cuando alguien comenta tu share).
  has_many :notifications, as: :notifiable, dependent: :destroy
end
