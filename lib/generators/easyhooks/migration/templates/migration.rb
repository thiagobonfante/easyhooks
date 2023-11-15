class EasyhooksMigration < ActiveRecord::Migration[6.0]
  def self.up
    create_table :easyhooks_stored_triggers do |t|
      t.string :name, null: false
      t.string :method, null: false
      t.string :endpoint, null: false
      t.timestamps null: true
    end
    add_index :easyhooks_stored_triggers, %i[name], unique: true
  end

  def self.down
    drop_table :easyhooks_stored_triggers
  end
end
