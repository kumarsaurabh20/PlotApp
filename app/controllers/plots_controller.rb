class PlotsController < ApplicationController
  # GET /plots
  # GET /plots.xml

require 'rubygems'
require 'rinruby'

  def index
	
      sample_size = 12
      R.eval "x <- rnorm(#{sample_size})"
      R.eval "summary(x)"
      R.eval "sd(x)"     

      @copy_of_x = R.pull "x"

      

        #code from http://nsaunders.wordpress.com/2009/05/20/baby-steps-with-rsruby-in-rails/ 
        # next 6 lines use R to plot a histogram
	#  @r = InitR()
	#  @d = @r.rnorm(1000)
	#  @l = @r.range(-4,4,@d)
	#  @r.png "/tmp/plot.png"
	#  @r.par(:bg => "cornsilk")
	#  @r.hist(@d, :range => @l, :col => "lavender", :main => "My Plot")
	#  @r.eval_R("dev.off()")  #required for png output
	#  # then read the png file and deliver it to the browser
	#  @g = File.open("/tmp/plot.png", "rb") {|@f| @f.read}
	#  send_data @g, :type=>"image/png", :disposition=>'inline'
   end

end
