class CreatePictures < ActiveRecord::Migration
  def change
    create_table :pictures do |t|
      t.string :photo
      t.text :comment

      t.timestamps null: false
    end
  end
end
