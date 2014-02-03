class AddColumnsToPlots < ActiveRecord::Migration
  def self.up
    add_column :plots, :calibFile, :binary
  end

  def self.down
    remove_column :plots, :calibFile
  end
end
