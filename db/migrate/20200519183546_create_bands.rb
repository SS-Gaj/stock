class CreateBands < ActiveRecord::Migration[6.0]
  def change
    create_table :bands do |t|
      t.datetime :bn_date
      t.string :bn_head
      t.string :novelty
      t.string :bn_url
      t.integer :bn_action

      t.timestamps
    end
  end
end
