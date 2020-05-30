class CreateOverlooks < ActiveRecord::Migration[6.0]
  def change
    create_table :overlooks do |t|
      t.date :lk_date
      t.string :lk_file

      t.timestamps
    end
  end
end
