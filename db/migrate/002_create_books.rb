class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.string :title, null: false
      t.integer :pages, null: false
      t.integer :author_id, null: false
      t.timestamps null: false
    end
  end
end
