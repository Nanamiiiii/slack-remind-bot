class CreateChannels < ActiveRecord::Migration[6.1]
  def change
    create_table :channels do |t|
      t.string :index
      t.string :ch_id

      t.timestamps
    end
  end
end
