class PlotsController < ApplicationController
  # GET /plots
  # GET /plots.xml

require 'rubygems'
require 'rinruby'
require 'paperclip'

 DIRECTORY = "public/calibration_data/"

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

      @savedfile = false

      uploaded_io = params[:plot][:calibFile]
 
      name = Time.now.strftime("%Y%m%d%H%M%S_") + sanitize_filename(uploaded_io.original_filename)
      
      Dir.mkdir(DIRECTORY) unless File.directory?(DIRECTORY)
      path = File.join(DIRECTORY, name)
      File.open(path, "wb") { |file| file.write(uploaded_io.read) } 
      @savedfile = true
      @plot.save
      id = @plot.id
      #save the name and directory of file in different variables in the database 
        
      respond_to do |format|
	 if @savedfile

             @forBubbleChart = []
             @output = []

             self.dataExtract(name)
             @output =  self.calTheta(id, name)

             @result = @output.shift        
             @thetaZeroValues = @output.shift             
             @thetaOneValues = @output.shift
            
             #puts @thetaOneValues.class
             @theta0 = @result.shift
             @theta1 = @result.shift
             
             #for precesion up to 3 decimal places. To make 2 decimal places change 200 to 20. 
             @result = round_up(@result)
             @thetaZeroValues = round_up(@thetaZeroValues)
             @thetaOneValues = round_up(@thetaOneValues)
             @forBubbleChart = @result #Both has same values, to be utilized in different graphs
             @result = array_to_hash(@result)
             
             @result = @result.sort_by { |keys, values| keys }

         format.html { render :html => @result }
	 format.xml  { render :xml => @result }

	 else
         format.html { render :action => "new" }
	 format.xml  { render :xml => @plot.errors, :status => :unprocessable_entity }
	 end
       end
  end

 
  #Method to read calibration data from the file and send querries to R and get the resulting data
  def calTheta(id, name)

      result_array = [] 
 
      @plot = Plot.find(id)
      num_of_variables = dataExtract(name)       
      path = File.join(DIRECTORY, name)
      str = IO.read(path)
      line = str.to_str
      @x1 = Array.new
      @y = Array.new 
      @raw_data = Array.new
      @raw_data_mod = Array.new
     if num_of_variables == 2
	      data = line.scan(/(\S+[\t,]\S+)/).flatten
             	
	      data.each do |line|
	      if line =~ /((\S+)[\t,](\S+))/
		      @x1.push $2               
		      @y.push $3                
                      @raw_data.push $1                
	      end                                          
	 end
        @raw_data_mod = check_file_return_mod(@raw_data) 
        result_array =  univariate_data(@x1, @y)
     end   
   return result_array
  end

  def univariate_data(x, y)

     R.assign "x1", x #assigning x axis data
     R.assign "y", y   #assigning y axis data

     R.eval  <<-EOF
      alpha <- 0.001
      num_iters <- 500
      x1 <- as.numeric(x1)
      y <- as.numeric(y)
      numOfRows <- length(y)
      frame1 <- data.frame(d0=rep(1,each=length(y)), d1=y)
      mX <- data.matrix(frame1)
      theta = data.matrix(data.frame(theta0=0, theta1=0))
      thetaRep = data.matrix(data.frame(theta0=rep(0, num_iters), theta1=rep(0, num_iters)))
      histSEF <- rep(0, each=num_iters)
      computeLineOfFit <- function(mX, y, theta) {
      m <- length(y)
      SEF <- 0
          for(i in 1:m) {
          SEF <- SEF + (1/(2*m)) * (mX[i,] %*% t(theta) - y[i])^2
        }
      return(SEF)
      }
     
      gradDescentUniVar <- function(mX, y, theta, alpha, num_iters) {
      m <- length(y)
      for(iter in 1:num_iters) {
        init <- 0
          for(i in 1:m) {
            init <- init + (alpha/m) * (mX[i,] %*% t(theta) - y[i]) * mX[i,]                 
          }
      theta = theta - init
      thetaRep[iter,] = theta
      histSEF[iter] <- computeLineOfFit(mX,y,theta)
      }
      output <- list(thetaOriVal=theta, thetaAll=thetaRep, J=histSEF)
      return(output) 
    }
   
    allResults <- gradDescentUniVar(mX,y,theta,alpha,num_iters)
    resultsUnlist <- unlist(allResults)  
 
    thetaValues <- allResults[[2]]
    thetaValuesFrame <- data.frame(thetaValues)
    theta0Values <- thetaValuesFrame$theta0
    theta1Values <- thetaValuesFrame$theta1
    allResults[[2]] <- NULL
    resultsUnlist <- unlist(allResults)
   EOF

     return R.resultsUnlist, R.theta0Values, R.theta1Values
  end

  def multivariate_data(y, *args)

       R.assign "Y", y
       R.assign "X1", args[0]
       R.assign "X2", args[1]
       R.assign "X3", args[2] || nil if args[2].nil?

       R.eval <<-EOF

       alpha <- as.numeric(alpha)
       num_iters <- as.numeric(num_iters)

       x1 <- as.numeric(X1)
       x2 <- as.numeric(X2)
       x3 <- as.numeric(X3)
        y <- as.numeric(Y)
       numOfRows <- length(y)



       if(length(x3) == 0) {
          mX <- cbind(x1,x2)
          mean <- cbind(mean(mX[,1]), mean(mX[,2]))
          sd <- cbind(sd(mX[,1]), sd(mX[,2]))
          theta = t(data.matrix(data.frame(theta0=0, theta1=0, theta2=0)))
       } else {
          mX <- cbind(x1,x2,x3)
          mean <- cbind(mean(mX[,1]), mean(mX[,2]), mean(mX[,3]))
          sd <- cbind(sd(mX[,1]), sd(mX[,2]), sd(mX[,3]))
          theta = t(data.matrix(data.frame(theta0=0, theta1=0, theta2=0, theta3=0)))
        }
     
       con <- rep(1, length(y))
       mX <- (mX - (con %*% mean))/(con %*% sd)
       cX <- cbind(x0=rep(1,each=length(y)), mX)

      SEF <- function(cX, y, theta) {  
             m <- length(y)
             J <- 0         
             J <- (1/(2*m)) * t((cX %*% theta) - y) %*% ((cX %*% theta) - y)  
      }

      multiGradDesc <- function(cX, y, theta, alpha, num_iters) {
                       histSEF <- rep(0, each=num_iters)  
                       m = length(y) 
      
           for(iter in 1:num_iters) {
         
                theta = theta - (alpha/m) * t(t((cX %*% theta) - y) %*% cX)
                histSEF[iter] <- SEF(cX,y,theta)

       }
       output <- list(thetaOriVal=theta, J=histSEF)
       return(output)
      }

   allResults <- multiGradDesc(cX,y,theta,alpha,num_iters)
   resultsUnlist <- unlist(allResults) 

   EOF
       
   return R.resultsUnlist
      
  end

  def lm_method


  end

  def line_method

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

  #checks how many columns does data table has(weather a multivariate or univariate data)
  def dataExtract(name)     
      #directory = "public/calibration_data/" 
      explVariable = 0
      columns = []
      path = File.join(DIRECTORY, name)
      #logger.debug "File extract local path: " + path
      file = File.open(path, "r") do |f|
             f.each do |line|
             #logger.debug "[" + f.lineno.to_s + "]" + line
             columns = line.split(/[,\t\s]/)
             end
          end 
     return explVariable = columns.length      
   end


   def sanitize_filename(file_name)  
     just_filename = File.basename(file_name.to_s)
     return just_filename.sub(/[^\w\.\-]/,'_')
   end
 
 #creates a map of key-value pairs for iterations and J function
  def array_to_hash(array)      
      count=0

      hash = Hash.new
      (array.length).times do 
      hash[count+1] = array[count]
      count += 1
      end
     return hash
   end

 #rounding up the theta and J function values.
  def round_up(object)
     object = object.map do  |x|      
              (x*200).round / 200.0
              end
   return object
  end

 #check if the calibration file is tab or comma separated(for scatter plot graph)
 #mod_file_name is the modified file in case the file_name_ori is tab separated 
  def check_file_return_mod(file_name_ori)
         mod_file_name = Array.new       

        if file_name_ori.first.include?(',')
           file_name_ori.each do |x|
           mod_file_name.push x
          end
        else
           file_name_ori.each do |x|
           mod_file_name.push x.to_s.gsub(/\t/, ',')
          end
        end
       
     return mod_file_name
  end


end


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

#png("/tmp/myplot.png")
# plot(1:num_iters, histSEF, xlab="Number of Iterations", ylab="Minimized Squared error function",     #main="Gradient Descent Check")
#@plot.save
#@plot.plot_images.create(:graph => File.new("/tmp/myplot.png", "rb"))
