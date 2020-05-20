class AddIndexToBandsBnDate < ActiveRecord::Migration[6.0]
  def change
    add_index :bands, :bn_date
  end
end
