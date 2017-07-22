module PictureHelper
  def choose_new_or_edit
    if action_name == 'new' || action_name == 'create'
      picture_index_path
    elsif action_name == 'edit' || action_name == 'update'
      picture_path
    end
  end
end
