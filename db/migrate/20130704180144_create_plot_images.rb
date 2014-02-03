class CreatePlotImages < ActiveRecord::Migration
  def self.up
    create_table :plot_images do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :plot_images
  end
end
