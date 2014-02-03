class AddColumnsToPlot < ActiveRecord::Migration
  def self.up
    add_column :plots, :explVariable, :integer
    add_column :plots, :respVariable, :integer
    add_column :plots, :expName, :string
  end

  def self.down
    remove_column :plots, :expName
    remove_column :plots, :respVariable
    remove_column :plots, :explVariable
  end
end
