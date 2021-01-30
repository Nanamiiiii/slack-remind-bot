class CreateMessages < ActiveRecord::Migration[6.1]
  def change
    create_table :messages do |t|
      t.string :userid
      t.string :t_stamp

      t.timestamps
    end
  end
end
