class Upload < ActiveRecord::Base

attr_accessible :inten, :calib

has_attached_file :inten
validates_attachment :inten, :presence => true,
  :content_type => { :content_type => ['text/csv', 'application/xls'] },
  :size => { :in => 0..50.megabytes }

has_attached_file :calib
validates_attachment :calib, :presence => true,
  :content_type => { :content_type => ['text/csv', 'application/xls'] },
  :size => { :in => 0..50.megabytes }


end
