class Picture < ActiveRecord::Base
  validates :comment, presence:true, length: {maximum: 140}
  validates :photo, presence: true

  belongs_to :user
  mount_uploader :photo, PhotoUploader
end
