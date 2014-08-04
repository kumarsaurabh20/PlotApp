class Predict < ActiveRecord::Base
  # attr_accessible :title, :body

 #attr_accessible :coeffs, :rawinten


 has_attached_file :coeffs, :url => "/:attachment/:id/:basename.:extension",
                   :path => ":rails_root/public/Predict/:attachment/:id/:basename.:extension"
#validates_attachment :coeffs, :presence => true,
#  :content_type => { :content_type => ['text/csv', 'application/xls'] },
#  :size => { :in => 0..50.megabytes }


has_attached_file :rawinten, :url => "/:attachment/:id/:basename.:extension",
                          :path => ":rails_root/public/Predict/:attachment/:id/:basename.:extension"
#validates_attachment :rawinten, :presence => true,
#  :content_type => { :content_type => ['text/csv', 'plain/text', 'gpr' , 'application/xls'] },
#  :size => { :in => 0..50.megabytes }

has_attached_file :repone, :url => "/:attachment/:id/:basename.:extension",
                          :path => ":rails_root/public/Predict/Replicate/:id/:basename.:extension"

has_attached_file :reptwo, :url => "/:attachment/:id/:basename.:extension",
                          :path => ":rails_root/public/Predict/Replicate/:id/:basename.:extension"

has_attached_file :repthree, :url => "/:attachment/:id/:basename.:extension",
                          :path => ":rails_root/public/Predict/Replicate/:id/:basename.:extension"




end
