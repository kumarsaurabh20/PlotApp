class AddAttachmentsGraphToPlot < ActiveRecord::Migration
  def self.up
    add_column :plots, :graph_file_name, :string
    add_column :plots, :graph_content_type, :string
    add_column :plots, :graph_file_size, :integer
    add_column :plots, :graph_updated_at, :datetime
  end

  def self.down
    remove_column :plots, :graph_file_name
    remove_column :plots, :graph_content_type
    remove_column :plots, :graph_file_size
    remove_column :plots, :graph_updated_at
  end
end
