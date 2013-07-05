class AddAttachmentsGraphToPlotImage < ActiveRecord::Migration
  def self.up
    add_column :plot_images, :graph_file_name, :string
    add_column :plot_images, :graph_content_type, :string
    add_column :plot_images, :graph_file_size, :integer
    add_column :plot_images, :graph_updated_at, :datetime
  end

  def self.down
    remove_column :plot_images, :graph_file_name
    remove_column :plot_images, :graph_content_type
    remove_column :plot_images, :graph_file_size
    remove_column :plot_images, :graph_updated_at
  end
end
