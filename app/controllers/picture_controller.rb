class PictureController < ApplicationController
  def index
    @pictures = Picture.all
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
    if @picture.save
      redirect_to picture_index_path, notice: "投稿しました！"
    else
      render 'new'
    end
  end

  private
    def picture_params
      params.require(:picture).permit(:photo, :photo_cache, :comment)
    end
end
