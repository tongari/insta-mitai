module PictureHelper
  def choose_new_or_edit

    if action_name == 'new' || 'create'
      picture_index_path
    elsif action_name == 'edit'
      picture_path
    end
  end
end
