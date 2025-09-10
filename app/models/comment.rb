class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :commentable, polymorphic: true # esto indica que puede tener una relacion polymorfica , ya sea post o share
end
