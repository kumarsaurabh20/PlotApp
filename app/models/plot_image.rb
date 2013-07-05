class PlotImage < ActiveRecord::Base

belongs_to :plot

has_attached_file :graph, :styles => {:small => "300x300>"},
                          :url => "/:attachment/:id/:style/:basename.:extension",
                          :path => ":rails_root/public/:attachment/:id/:style/:basename.:extension",
             
                          :default_style => :small  

end
