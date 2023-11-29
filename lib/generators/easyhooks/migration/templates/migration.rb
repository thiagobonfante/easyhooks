# frozen_string_literal: true

class EasyhooksMigration < ActiveRecord::Migration[6.0]
  def self.up
    create_table :easyhooks_store do |t|
      t.string :context, null: false
      t.string :name, null: false
      t.string :method, null: false
      t.string :endpoint, null: false
      t.timestamps null: true
    end
    add_index :easyhooks_store, %i[name context], unique: true

    create_table :easyhooks_store_values do |t|
      t.string :context, null: false
      t.string :key, null: false
      t.string :value, null: false
      t.integer :store_id, null: false, references: :easyhooks_store
      t.timestamps null: true
    end
    add_index :easyhooks_store_values, %i[context key]
  end

  def self.down
    drop_table :easyhooks_store_values
    drop_table :easyhooks_store
  end
end
