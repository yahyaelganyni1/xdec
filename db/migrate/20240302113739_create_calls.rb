class CreateCalls < ActiveRecord::Migration[7.0]
  def change
    create_table :calls do |t|
      t.integer :agent_id
      t.references :conversation, foreign_key: true
      t.string :contact_id
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
