class PictureController < ApplicationController
  before_action :authenticate_user!
  before_action :set_picture, only:[ :edit, :update, :destroy]
  before_action :checkMatchUser, only:[:edit, :destroy]

  def index
    @pictures = Picture.all
    @userId = current_user.id
  end

  def new
    if request.post?
      @picture = Picture.new(picture_params)
    else
      @picture = Picture.new
    end
  end

  def create
    @picture = Picture.new(picture_params)
    @picture.user_id = current_user.id

    if @picture.save
      redirect_to picture_index_path, notice: "投稿しました！"
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @picture.update(picture_params)
      redirect_to picture_index_path, notice: "更新しました！"
    else
      render 'edit'
    end
  end

  def destroy
    @picture.destroy
    redirect_to picture_index_path, notice: "削除しました"
  end

  private
    def picture_params
      params.require(:picture).permit(:photo, :photo_cache, :comment)
    end

    def set_picture
      @picture = Picture.find(params[:id])
    end

    def checkMatchUser
      if current_user.id != @picture.user_id
        redirect_to picture_index_path
      end
    end
end
