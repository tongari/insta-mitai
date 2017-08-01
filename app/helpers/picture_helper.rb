module PictureHelper
  def choose_new_or_edit
    if action_name == 'new' || action_name == 'create'
      picture_index_path
    elsif action_name == 'edit' || action_name == 'update'
      picture_path
    end
  end

  def profile_img(user)
    return image_tag(user.avatar, alt: user.name, class: 'regist__profile') if user.avatar?

    unless user.provider.blank?
      img_url = user.image_url
    else
      img_url = 'def_profile.svg'
    end
    image_tag(img_url, alt: user.name, class: 'regist__profile')
  end

end
