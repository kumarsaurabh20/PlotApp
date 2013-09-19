class PlotsController < ApplicationController
  # GET /plots
  # GET /plots.xml

require 'rubygems'
require 'rinruby'
require 'paperclip'

  def index

     @plot = Plot.all
      
  end

  def new 

       @plot = Plot.new
       @title = "New Calibration Data Upload"

       respond_to do |format|
       format.html #new.html.erb
       format.xml {render :xml => @plot}
       end
  end

   def create
      
      @plot = Plot.new(params[:plot])
      @title = "Calibration Data Upload"
      logger.debug "here is the log: " + @plot.to_s

      @savedfile = false

      uploaded_io = params[:plot][:calibFile]
      logger.debug "here is the log: " + uploaded_io.to_s
 
      name = Time.now.strftime("%Y%m%d%H%M%S_") + sanitize_filename(uploaded_io.original_filename)
      logger.debug "here is the log: " + name.to_s

      #name =  Time.now.strftime("%Y%m%d%H%M%S ") + sanitize_filename(uploaded_io.original_filename)
      #name =  Time.now.strftime("%Y%m%d%H%M%S ") + sanitize_filename(uploaded_io.original_filename)
 
      directory = "public/calibration_data/"
      Dir.mkdir(directory) unless File.directory?(directory)
      path = File.join(directory, name)
      File.open(path, "wb") { |file| file.write(uploaded_io.read) } 
      @savedfile = true
      @plot.save
      id = @plot.id
      #save the name and directory of file in different variables in the database 
        
      respond_to do |format|
	 if @savedfile

             self.dataExtract(name)
             @result =  self.calTheta(id, name)
             @theta0 = @result.shift
             @theta1 = @result.shift
             
             #for precesion up to 3 decimal places. To make 2 decimal places change 200 to 20. 
             @result = @result.map do  |x|      
                       (x*200).round / 200.0
                       end
             #logger.debug "rounded numbers: " + @result.to_s

             @result = self.array_to_hash(@result)
             
             @result = @result.sort_by { |keys, values| keys }
             
             #logger.debug @result.to_s

         format.html { render :html => @result }
	      #flash[:notice] = 'Calibration data file is successfully saved.'
              #flash[:result] = @result
	      #redirect_to :controller => "plots", :action => "index"
	 format.xml  { render :xml => @result }
	 else
         format.html { render :action => "new" }
	 format.xml  { render :xml => @plot.errors, :status => :unprocessable_entity }
	 end
       end

  end

  def array_to_hash(array)
      
     count=0

     hash = Hash.new
     (array.length).times do 
     hash[count+1] = array[count]
     count += 1
     end
     return hash

  end


  def dataExtract(name)
      
      directory = "public/calibration_data/" 
      
      path = File.join(directory, name)
      logger.debug "File extract local path: " + path
      file = File.open(path, "r") do |f|
             f.each do |line|
             logger.debug "[" + f.lineno.to_s + "]" + line
             columns = line.split(",") 
            end
          end 
  end


  def sanitize_filename(file_name)
  
    just_filename = File.basename(file_name.to_s)
    return just_filename.sub(/[^\w\.\-]/,'_')
 
  end

  def calTheta(id, name)

      @plot = Plot.find(id)
      explanatoryVar = @plot.explVariable
      responseVar = @plot.respVariable
      directory = "public/calibration_data/" 
      path = File.join(directory, name)
      logger.debug "File extract local path: " + path
      str = IO.read(path)
      line = str.to_str
      @x1 = Array.new
      @y = Array.new 
     if explanatoryVar == 1
	      data = line.scan(/(\S+,\S+)/).flatten
              #logger.debug "here is data" + data.to_s	
	      data.each do |line|
	      if line =~ /(\S+),(\S+)/
		      @x1.push $1 
                # logger.debug "here is @x1" + @x1.to_s
		      @y.push $2
                # logger.debug "here is @y" + @y.to_s                 
	      end 
	    end
      R.assign "x1", @x1
      R.assign "y", @y
      R.eval  <<-EOF
      alpha <- 0.01
      num_iters <- 150
      x1 <- as.numeric(x1)
      y <- as.numeric(y)
      numOfRows <- length(y)
      frame1 <- data.frame(d0=rep(1,each=length(y)), d1=y)
      mX <- data.matrix(frame1)
      theta = data.matrix(data.frame(theta0=0, theta1=0))
      histSEF <- rep(0, each=num_iters)
      computeLineOfFit <- function(mX, y, theta) {
      m <- length(y)
      SEF <- 0
          for(i in 1:m) {
          SEF <- SEF + (1/(2*m)) * (mX[i,] %*% t(theta) - y[i])^2
        }
      return(SEF)
      }
     
      gradDescentUniVar <- function(mX,y,theta,alpha,num_iters) {
      m <- length(y)
      for(iter in 1:num_iters) {
        init <- 0
          for(i in 1:m) {
            init <- init + (alpha/m) * (mX[i,] %*% t(theta) - y[i]) * mX[i,]                 
          }
      theta = theta - init
      histSEF[iter] <- computeLineOfFit(mX,y,theta)
      print(histSEF)
      }
      output <- list(thetaVal=theta, J=histSEF)
      return(output) 
    }
   a <- gradDescentUniVar(mX,y,theta,alpha,num_iters)
   b <- unlist(a)   
   EOF
#png("/tmp/myplot.png")
# plot(1:num_iters, histSEF, xlab="Number of Iterations", ylab="Minimized Squared error function",     #main="Gradient Descent Check")
#@plot.save
#@plot.plot_images.create(:graph => File.new("/tmp/myplot.png", "rb"))

output = R.b
    
#    elsif explanatoryVar == 2
#
#             data = line.scan(/(\S+,\S+,\S+)/).flatten
#	     data.each do |line|
#
#	      if line =~ /(\S+),(\S+),(\S+)/
#                    
#		      @x1 = $1 
#		      @x2 = $2
#		      @y= $3    
#	      end 
#	    end
#      
#    elsif explanatoryVar == 3
#               
#             data = line.scan(/(\S+,\S+,\S+,\S+)/).flatten
#	     data.each do |line|
#
#	      if line =~ /(\S+),(\S+),(\S+),(\S+)/
#               
#		      @x1 = $1 
#		      @x2 = $2 
#		      @x3 = $3 
#		      @y = $4  
#	      end 
#	    end
#
#    elsif explanatoryVar == 4
#
#            data = line.scan(/(\S+,\S+,\S+,\S+,\S+)/).flatten
#	     data.each do |line|
#
#	      if line =~ /(\S+),(\S+),(\S+),(\S+),(\S+)/
#
#		      @x1 = $1 
#		      @x2 = $2 
#		      @x3 = $3 
#		      @x4 = $4
#		      @y = $5   		  
#	      end 
#	    end
#
#    else 
#      
#        data = line.scan(/(\S+,\S+,\S+,\S+,\S+,\S+)/).flatten
#        data.each do |line|
#
#	      if line =~ /(\S+),(\S+),(\S+),(\S+),(\S+),(\S+)/
#
#		      @x1 = $1 
#		      @x2 = $2 
#		      @x3 = $3 
#		      @x4 = $4
#		      @x5 = $4
#		      @y = $5     		  
#	      end 
#	    end
#
#
    end

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
