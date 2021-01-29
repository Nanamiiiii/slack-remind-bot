class CreateReminders < ActiveRecord::Migration[6.1]
  def change
    create_table :reminders do |t|
      t.datetime :remind_day
      t.text :comment

      t.timestamps
    end
  end
end
