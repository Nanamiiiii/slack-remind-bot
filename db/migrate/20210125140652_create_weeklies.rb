class CreateWeeklies < ActiveRecord::Migration[6.1]
  def change
    create_table :weeklies do |t|
      t.integer :day
      t.time :remind_time
      t.integer :offset
      t.string :place

      t.timestamps
    end
  end
end
