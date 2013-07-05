class PlotsController < ApplicationController
  # GET /plots
  # GET /plots.xml

require 'rubygems'
require 'rinruby'
require 'paperclip'

  def index

     @plot = Plot.new
	
      sample_size = 5
      R.eval  <<-EOF
      x <- rnorm(#{sample_size})
      summary(x)
      sd(x)
      y <- rnorm(5)
      png("/tmp/myplot.png")
      plot(x,y)
      dev.off()     
     EOF

      
     @copy_of_x = R.pull "x"     
     @plot.save
     @plot.plot_images.create(:graph => File.new("/tmp/myplot.png", "rb"))
        
   end

  # GET /micro_array_images/1
  # GET /micro_array_images/1.xml
  def show

    @plot = Plot.find(params[:id])
    @title = "Plot Image"

	    if @plot.nil?
		redirect_to :action => "index"
	    end

	    respond_to do |format|
	      format.html # show.html.erb
	      format.xml  { render :xml => @plot }
	    end

  end


end


