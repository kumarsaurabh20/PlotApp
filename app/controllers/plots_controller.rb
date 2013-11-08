class PlotsController < ApplicationController

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
 
      namefile = Time.now.strftime("%Y%m%d%H%M%S_") + sanitize_filename(uploaded_io.original_filename)
      
      Dir.mkdir(DIRECTORY) unless File.directory?(DIRECTORY)
      path = File.join(DIRECTORY, namefile)
      File.open(path, "wb") { |file| file.write(uploaded_io.read) } 
      @savedfile = true
      @plot.save
      id = @plot.id
      #save the name and directory of file in different variables in the database 
        
      respond_to do |format|
	 if @savedfile

             @thetaTwoValues, @thetaThreeValues, @theta2, @theta3, @thetaTwoValues, @thetaThreeValues, @forBubbleChart, @output = [],[],[],[],[],[],[],[]

             dataExtract(namefile)
             @output = calTheta(namefile)
             #logger.debug @output.inspect
             @result = @output.shift
             @theta0 = @result.shift
             @theta1 = @result.shift
             @thetaZeroValues = @output.shift             
             @thetaOneValues = @output.shift

             if @output.length > 1                     
                  @thetaTwoValues = @output.shift
                  @thetaThreeValues = @output.shift
                  @theta2 = @result.shift
                  @theta3 = @result.shift 
                  @thetaTwoValues = round_up(@thetaTwoValues)
                  @thetaThreeValues = round_up(@thetaThreeValues)                       
             end

             #for precesion up to 3 decimal places. To make 2 decimal places change 200 to 20. 
                @result = round_up(@result)
                @thetaZeroValues = round_up(@thetaZeroValues)
                @thetaOneValues = round_up(@thetaOneValues)
                
                @forBubbleChart = @result #Both has same values, but to be utilized in different graphs
                @result = array_to_hash(@result)
                @result = @result.sort_by { |keys, values| keys }
             
         format.html { render :html => @result }
	 format.xml  { render :xml => @output }

	 else
         format.html { render :action => "new" }
	 #format.xml  { render :xml => @plot.errors, :status => :unprocessable_entity }
	 end
       end
  end
 
  #Method to read calibration data from the file and send querries to R and get the resulting data
  def calTheta(name)

      @y, @x1, @x2, @x3, @raw_data, @raw_data_mod, @result_array = [], [], [], [], [], [], []
 
      num_of_variables = dataExtract(name)       
      path = File.join(DIRECTORY, name)
      str = IO.read(path)
      line = str.to_str
   
      if num_of_variables == 2
	      data = line.scan(/(\S+[\t,]\S+)/).flatten
             	
	      data.each do |line|
	      if line =~ /((\S+)[\t,](\S+))/		                    
		      @y.push $2 
                      @x1.push $3                
                      @raw_data.push $1                
	      end                                          
	 end
        @raw_data_mod = check_file_return_mod(@raw_data) 
        @result_array =  univariate_data(@y, @x1)
   
     elsif num_of_variables == 3 
       
       #data = line.scan(/(\S+[\t,]\S+[\t,](\S+){0,1}[\t,]*\S+)/).flatten
       data = line.scan(/(\S+[\t,]\S+[\t,]\S+)/).flatten
             	
       data.each do |line|
	      if line =~ /((\S+)[\t,](\S+)[\t,](\S+))/
		      @y.push $2
                      @x1.push $3
                      @x2.push $4               
                      @raw_data.push $1                
	      end                       
                   
        end

       @raw_data_mod = check_file_return_mod(@raw_data) 
       @result_array =  multivariate_two_x(@y, @x1, @x2)

     elsif num_of_variables == 4 
       
       data = line.scan(/(\S+[\t,]\S+[\t,]\S+[\t,]\S+)/).flatten
             	
       data.each do |line|
	      if line =~ /((\S+)[\t,](\S+)[\t,](\S+)[\t,](\S+))/
		      @y.push $2
                      @x1.push $3
                      @x2.push $4
                      #if $4.nil?
                       #  @x3 = []
                      #else
                      @x3.push $5
                      #end		                     
                      @raw_data.push $1                
	      end                       
                   
        end
      
       #if !@x3.empty?
	#   @x3 = @x3.map do |obj|
	#	 obj.delete ","
	 #  end
       #end

       @raw_data_mod = check_file_return_mod(@raw_data) 
       @result_array =  multivariate_three_x(@y, @x1, @x2, @x3)
   else
       puts "Exception in number of column"
   end

   return @result_array

  end

  #data table with one positive control and hence one x column
  def univariate_data(y, x)

     
     R.assign "y", y   #assigning y axis data
     R.assign "x1", x #assigning x axis data

     R.eval  <<-EOF
      alpha <- 0.01
      num_iters <- 100
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
 
    thetaValues <- allResults[[2]]
    thetaValuesFrame <- data.frame(thetaValues)
    theta0Values <- thetaValuesFrame$theta0
    theta1Values <- thetaValuesFrame$theta1
    allResults[[2]] <- NULL
    resultsUnlist <- unlist(allResults)

   EOF

     return R.resultsUnlist, R.theta0Values, R.theta1Values
  end

  def multivariate_two_x(y, x1, x2)

       R.assign "Y", y
       R.assign "X1", x1
       R.assign "X2", x2
       #R.assign "X3", columns[3] #|| nil if columns[3].nil?

       R.eval <<-EOF

       alpha <- 0.01
       num_iters <- 700
       x1 <- as.numeric(X1)
       x2 <- as.numeric(X2)
        y <- as.numeric(Y)
       mX <- cbind(x1,x2)
       mean <- cbind(mean(mX[,1]), mean(mX[,2]))
       sd <- cbind(sd(mX[,1]), sd(mX[,2]))
       numOfRows <- length(y)
       theta = t(data.matrix(data.frame(theta0=0, theta1=0, theta2=0))) 
       thetaRep = data.matrix(data.frame(theta0=rep(0, num_iters), theta1=rep(0, num_iters), theta2=rep(0, num_iters)))
     
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
                thetaRep[iter,] = theta
                histSEF[iter] <- SEF(cX,y,theta)

               }
       output <- list(thetaOriVal=theta, thetaAll=thetaRep, J=histSEF) 
       return(output)
     }

   allResults <- multiGradDesc(cX,y,theta,alpha,num_iters)

    thetaValues <- allResults[[2]]
    thetaValuesFrame <- data.frame(thetaValues)
    theta0Values <- thetaValuesFrame$theta0
    theta1Values <- thetaValuesFrame$theta1
    theta2Values <- thetaValuesFrame$theta2
    allResults[[2]] <- NULL
    resultsUnlist <- unlist(allResults)

   EOF
      
   return R.resultsUnlist, R.theta0Values, R.theta1Values, R.theta2Values
      
  end

  def multivariate_three_x(y, x1, x2, x3)

      R.assign "Y", y
       R.assign "X1", x1
       R.assign "X2", x2
       R.assign "X3", x3

       R.eval <<-EOF

       alpha <- 0.01
       num_iters <- 700
       x1 <- as.numeric(X1)
       x2 <- as.numeric(X2)
       x3 <- as.numeric(X3)
        y <- as.numeric(Y)
       numOfRows <- length(y)
            
       mX <- cbind(x1,x2,x3)
       mean <- cbind(mean(mX[,1]), mean(mX[,2]), mean(mX[,3]))
       sd <- cbind(sd(mX[,1]), sd(mX[,2]), sd(mX[,3]))
       theta = t(data.matrix(data.frame(theta0=0, theta1=0, theta2=0, theta3=0)))
       thetaRep = data.matrix(data.frame(theta0=rep(0, num_iters), theta1=rep(0, num_iters), theta2=rep(0, num_iters), theta3=rep(0, num_iters)))
         
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
                thetaRep[iter,] = theta
                histSEF[iter] <- SEF(cX,y,theta)

               }
       output <- list(thetaOriVal=theta, thetaAll=thetaRep, J=histSEF) 
       return(output)
     }

   allResults <- multiGradDesc(cX,y,theta,alpha,num_iters)

    thetaValues <- allResults[[2]]
    thetaValuesFrame <- data.frame(thetaValues)
    theta0Values <- thetaValuesFrame$theta0
    theta1Values <- thetaValuesFrame$theta1
    theta2Values <- thetaValuesFrame$theta2
    theta3Values <- thetaValuesFrame$theta3
    allResults[[2]] <- NULL
    resultsUnlist <- unlist(allResults)

   EOF
      
   return R.resultsUnlist, R.theta0Values, R.theta1Values, R.theta2Values, R.theta3Values
      
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


  def cal_s2c(columns=[*args]) 

    result, output, block = [], [], []
    
    if columns.length == 2   
    result = univariate_data(columns[0], columns[1])
    block = result.shift
    output.push block.shift
    output.push block.shift
    
    elsif columns.length == 3   
    result = multivariate_two_x(columns[0], columns[1], columns[2]) 
    block = result.shift
    output.push block.shift
    output.push block.shift
    output.push block.shift
    else
    result = multivariate_three_x(columns[0], columns[1], columns[2], columns[2])   
    block = result.shift
    output.push block.shift
    output.push block.shift
    output.push block.shift
    output.push block.shift
    end
  
    respond_to do |format|
	   format.xml { render :xml => output }
	end

  end





end


#png("/tmp/myplot.png")
# plot(1:num_iters, histSEF, xlab="Number of Iterations", ylab="Minimized Squared error function",     #main="Gradient Descent Check")
#@plot.save
#@plot.plot_images.create(:graph => File.new("/tmp/myplot.png", "rb"))
