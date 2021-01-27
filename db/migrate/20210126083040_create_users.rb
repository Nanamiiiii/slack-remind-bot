class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users do |t|
      t.string :slack_id
      t.boolean :valid_user

      t.timestamps
    end
  end
end
