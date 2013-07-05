class Plot < ActiveRecord::Base

has_many :plot_images

accepts_nested_attributes_for :plot_images, :allow_destroy => true

end
