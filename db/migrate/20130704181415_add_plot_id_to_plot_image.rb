class AddPlotIdToPlotImage < ActiveRecord::Migration
  def self.up
    add_column :plot_images, :plot_id, :integer
  end

  def self.down
    remove_column :plot_images, :plot_id
  end
end
