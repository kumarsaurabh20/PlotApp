class PredictsController < ApplicationController
require 'matrix'
require 'csv'

attr_accessor :raw_inten_transpose, :coeffs_transpose, :probe_list, :id, :data

class NoGprError < StandardError
end

  # GET /predicts
  # GET /predicts.json
  def index
    @predicts = Predict.all

    @predict = Predict.new

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @predicts }
    end
  end

  # POST /predicts
  # POST /predicts.json
  def create
    @predict = Predict.new(params[:predict])

    respond_to do |format|
      if @predict.save

        @id = @predict.id
        
        coeffs_path, raw_inten_path = get_paths(id)
        @raw_inten_transpose = import(raw_inten_path)
        logger.debug @raw_inten_transpose.to_s + "##############################################"  

        @coeffs_transpose = import(coeffs_path)
        @probe_list = @raw_inten_transpose[0]

        flash[:notice] = "Files were successfully uploaded!!"
        format.html { render "calculate" }
      else
        format.html { render action: "index" }
        format.json { render json: @predict.errors, status: :unprocessable_entity }
      end
    end
  end

 #method recieving Ajax request from the view posting selected probes for normalization
 #cell count prediction calculation are done in this method
 def calculate

     #logger.debug @cell_counts.to_s
     #ajax request; filter out id from rest of the array/ajax request
     @data = params['data'].split(',') 
     @id = @data.shift
     logger.debug @data.to_s

     #fetch saved file paths
     coeffs_path, rawintens_path = get_paths(id)
     
     #file data in R input compatible format (currently its 2D array as row vectors)
     @coeffs_transpose = import(coeffs_path)
     logger.debug @coeffs_transpose.to_s
     @raw_inten_transpose = import(rawintens_path)
     logger.debug @raw_inten_transpose

     counter = 0
     for i in 1..@coeffs_transpose.count
           R.assign "col#{i}", @coeffs_transpose[i-1]
           counter = counter + 1
     end

     for i in 1..@raw_inten_transpose.count
         R.assign "inten_col#{i}", @raw_inten_transpose[i-1]
     end 

     R.assign "count", counter
     R.assign "norm_probes", @data
     R.eval <<-EOF
    
     coeffs_matrix <- matrix(0, length(col1), count)
     inten_matrix <- matrix(0, length(inten_col1), 2)
     
     for (i in c(1:count)) {
         if (i == 1) { coeffs_matrix <- cbind(get(paste0("col",i))) } 
         else { coeffs_matrix <- cbind(coeffs_matrix, get(paste0("col",i))) }    
         }
    
     for (i in c(1:2)) { 
       if (i == 1) { inten_matrix <- cbind(get(paste0("inten_col",i))) } 
       else { inten_matrix <- cbind(inten_matrix, get(paste0("inten_col",i))) }    
     }

      norm_val <- matrix(0, length(norm_probes), 1)
     
       for (i in 1:length(norm_probes)) {
        dummy <- inten_matrix[norm_probes[i] == inten_matrix[,1]]
        print(dummy)
        dummy <- dummy[-1]
        norm_val[i,] <- dummy
        }

      length <- length(norm_probes) - 1
      for (i in 1:length) { inten_matrix <- cbind(inten_matrix, inten_matrix[,2])}

      column_filter <- inten_matrix[, -1]
      col <- ncol(column_filter)
      row <- nrow(column_filter)
      tab_norm_1 <- matrix(0, row, col)

      for(i in c(1:col)) {tab_norm_1[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[i,1])}))}

     inten_norm_matrix <- cbind(inten_matrix[,1], tab_norm_1)

     convertNa <- function(x) {
	     y <- which(is.na(x)==TRUE)
	     x[y] <- 1
	     return(x)
     }

     getPrediction <- function(results, results2) {

        match_probes <- match(results[,1], results2[,1])
        dummyMatrix <- matrix(0, nrow(results), ncol(results) - 1)
        for (i in c(1:nrow(results))) { dummyMatrix[i,] <- results2[match_probes[i], ]}
        results2 <- dummyMatrix

	results_filter <- results[, -1]
	results2_filter <- results2[, -1]
	results2_filter <- apply(results2_filter,2, function(x) as.numeric(x))
	results_filter <- apply(results_filter,2, function(x) as.numeric(x))
	results_filter <- convertNa(results_filter)
	dummyMatrix <- matrix(1, nrow(results2_filter), 1)
	results2_filter <- cbind(dummyMatrix, results2_filter)
	
        cell_counts <- vector()
        for (i in c(1:nrow(results))) {cell_counts[i] <- sum(results_filter[i,] * results2_filter[i,])}
        result_with_matrix <- cbind(results2[,1], cell_counts)
	return(result_with_matrix)
     }

     results <- getPrediction(coeffs_matrix, inten_norm_matrix) 
     
      
EOF

 @results = R.pull("results")

 @countToView = Array.new

  for i in 0..@results.row_size
   	@countToView.push(@results.row(i).to_a)
  end

  #remove the last empty array from the matrix
  @countToView.pop
  #convert string formatted count values to nearby integer
  countToView_transpose = @countToView.transpose
  @counts = countToView_transpose[1].map {|x| x.to_i}
  @probes = countToView_transpose[0]

  #count the total number of vectors in the matrix
  @totalSize = @countToView.size

  #count total number of elements in the matrix, useful for counting <td> elements in the view
  @columnSize = @countToView[1].size
 
  
 #export a csv file containing coeffecients and keep it in public folder.
   
 
     #path to coeffs directory
     root_counts = '#{Rails.root}/public/Predict/counts'   

     #provide a name to the file having individual calibration ID
     namefile = Time.now.strftime("%Y%m%d%H%M%S_") + "cell_counts_file" + "_" + id + ".csv"

     #remove all previous csv coeffecients files
     #user have to caluclate coeffecients multiple times before performing prediction so its good
     #to delete all previous coeffs file and deal with the present
     #FileUtils.chmod 0777, root_coeffs, :verbose => true
     
     FileUtils.remove_dir "#{Rails.root}/public/Predict/counts", true
     
     #create a coeff directory in public folder of rails 
     counts_path = "#{Rails.root}/public/Predict/counts"
     Dir.mkdir(counts_path) unless File.directory?(counts_path)
    
     #create a file path
     path = File.join(counts_path, namefile)

  
     #call CSV class and open a new csv file 
     CSV.open(path, 'wb') do |csv|
         #use matrix class of ruby and check the row size of returned matrix.
         row_count = @results.row_size
         for i in 0..row_count         
         #extract individual row of matrix as vector and convert it to array and push it to csv line
		 csv << @results.row(i).to_a
	     end
     end

      
     respond_to do |format|
     format.html { render "calculate" }
     format.js     
     end 


 end


#===================================CALCULATE TSI==========================================================

 #method for parsing gpr file and calculating Total intensities from raw intensities
 def readGpr(file_path)
   begin      
	     read = IO.read(file_path)
             read.encode!('UTF-8', :invalid => :replace, :undef => :replace)
	     read_array = []
             read_array = read.split("\n") 



    # if read.valid_encoding?
       #read_array = read.split("\n")
	#		         
	#	     else
	#		 read_array = read.encode!("ASCII-8BIT","ASCII-8BIT", invalid: :replace, :undef => :replace).split("\n")
	#	     end
	    
	      mod_array = read_array.map {|e| e.split("\t")}  
	      
              logger.debug @mod_array.to_s + "++++++++++++++++++++++++++++++++++++++++++++++++++++"


	      element_stabilized = mod_array.map {|element| element.join(",").gsub("\"","").split(",")} 

	      header_removed = []
		      if element_stabilized [0].include?("ATF")
			 header_removed = element_stabilized.drop_while {|i| i unless i.include?("Block")}
		      else
			 raise NoGprError, "File does not seem to be GPR formatted. Check the file"
		      end

              column_based_array = header_removed.transpose

              @name, @dia, @f633_mean, @b633_mean = getColumns(column_based_array)



              @probeNames, @sorted_list = calTotalSignalIntensity(@name, @dia, @f633_mean, @b633_mean)
                  
              #@filterProbes, @sorted_list = sortGprTsiList(@name, @get_tsi_list)

              #logger.debug @filterProbes.to_s + "++++++++++++++++++++++++++++++++++++++++++++++++++++"
              #logger.debug @sorted_list.to_s + "++++++++++++++++++++++++++++++++++++++++++++++++++++"       
              
           return @probeNames, @sorted_list

    rescue Exception => e
              e.message
              e.backtrace.inspect
    end 

 end 

 def getColumns(array=[])
     name, dia, f633_mean, b633_mean = [], [],[],[]
	   begin
		     array.map do |element|     
			       case
				       when element.include?("Name") then name << element
           #logger.debug name.to_s + "++++++++++++++++++++++++++++++++++++++++++++++++++++"
				       when element.include?("Dia.") then dia << element

           #logger.debug dia.to_s + "++++++++++++++++++++++++++++++++++++++++++++++++++++"
				       when element.include?("F633 Mean") then f633_mean << element
           #logger.debug f633_mean.to_s + "++++++++++++++++++++++++++++++++++++++++++++++++++++"

				       when element.include?("B633 Mean") then b633_mean << element  
           #logger.debug b633_mean.to_s + "++++++++++++++++++++++++++++++++++++++++++++++++++++"
     
			       end
		     end
	   
	    rescue Exception => e
		   e.message
                   e.backtrace.inspect
	    end

    return name, dia, f633_mean, b633_mean 
 end

 def calTotalSignalIntensity(diameter, foreground, background)
 
   begin 
        dia = diameter.flatten 
        dia.shift
       #logger.debug dia.to_s + "++++++++++++++++++++++++++++++++++++++++++++++++++++"
        f633 = foreground.flatten
        f633.shift
       #logger.debug f633.to_s + "++++++++++++++++++++++++++++++++++++++++++++++++++++"      
        b633 = background.flatten
        b633.shift
       #logger.debug b633.to_s + "++++++++++++++++++++++++++++++++++++++++++++++++++++"

	#Formula for calculating Total Signal Intensity
	#(F633_mean - B633_mean)*3.14*diameter^2*1/4
	R.assign "dia", dia
	R.assign "f633", f633
	R.assign "b633", b633

  R.eval <<-EOF

	  calTSI <- function(dia, f633, b633) {

	  dia <- as.numeric(dia)
	  f633 <- as.numeric(f633)
	  b633 <- as.numeric(b633)

	  tsi <- (f633 - b633) * 3.14 * dia * dia * 1/4

	  return(tsi)
	} 

	list <- calTSI(dia, f633, b633)

   EOF

	tsi = R.pull("list")
 #logger.debug tsi.to_s + "++++++++++++++++++++++++++++++++++++++++++++++++++++"

        return tsi

   rescue Exception => e
        e.message
        e.backtrace.inspect
   end 

 end

 def sortGprTsiList(probeNameList, totalSignalIntensities)

     names = probeNameList.flatten
     names.shift
     filterProbeNames = names.uniq

     R.assign "names", names
     R.assign "totalSignalIntensities", totalSignalIntensities

     R.eval <<-EOF

        names <- as.vector(names)
        totalSignalIntensities <- as.numeric(totalSignalIntensities)

	tab <- cbind(Name=names, F633=totalSignalIntensities)
	tab <- data.frame(tab)	
 
	allProbes <- as.character(tab[,1])
	uniqueProbeVec <- unique(allProbes) 

	meanTSI <- list()
	myData <- list()

	for (i in c(1:length(uniqueProbeVec))) {
	    
		myData[[i]] <- subset(tab, uniqueProbeVec[i] == tab[ , 1])
	} 

	for (j in c(1:length(uniqueProbeVec))) {

                newVec <- as.numeric(as.character(myData[[j]][, 2]))
                replicate <- as.numeric(length(newVec))

		meanTSI[[j]] <- sum(newVec)/replicate
	}

	meanTSI <- as.numeric(unlist(meanTSI))  

     EOF
 
    #passing non UTF-8 char from R to ruby and vice versa throws an error... 
    #"Error in nchar(var) : invalid multibyte string 1". 
    #here is a workaround.
    #Sys.setlocale('LC_ALL','C')
    #http://stackoverflow.com/questions/6669911/error-in-nchar-when-reading-in-stata-file-in-r-on-mac


     tsiList = R.pull("meanTSI")
     

     return filterProbeNames, tsiList

 end

 def partition_array(array=[], size=500)
		dummy = []
	     begin
		if array.empty?
		   raise "Input array is empty!!"
		else
		array.each_slice(size) {|element| dummy.push(element)}
		end
	     rescue Exception => e
		   e.message
	     end     

     return dummy 
 end

      

#==================================INPUT FILE HANDLING============================================

 #method for fetching saved file path based on retrived upload ID from database
 #ID is required to fetch session specific file.
 def get_paths(id)
     #use ID argument to fetch that particular record.
     #with the help of id fetch the file names from database
     predict = Predict.find(id)
     coeffs_file_name = predict.coeffs_file_name
     rawintens_file_name = predict.rawinten_file_name

     #set the path to the file folder
     coeffs_path = "#{Rails.root}/public/Predict/coeffs"
     rawintens_path = "#{Rails.root}/public/Predict/rawintens"
      
     #create file paths and return them    
     coeffs_file = File.join(coeffs_path, coeffs_file_name)
     rawintens_file = File.join(rawintens_path, rawintens_file_name)
 
     return coeffs_file, rawintens_file
 end

 #method for parsing calibration data
 #check why its not working with the condition!!! Try to refactor import methods again
 def import(file_path)

     accepted_formats = [".csv"]
     begin
	     if accepted_formats.include? File.extname(file_path)
		     array = import_ori(file_path)
		     array_splitted = array.map {|a| a.split(",")} 
		     array_transpose = array_splitted.transpose
		     return array_transpose
	     else 
		    name, tsi = readGpr(file_path)
                    nameTsiArray = [ name, tsi ]
                    return nameTsiArray
	     end

     rescue Exception => e
            e.message
     end

 end
 
 #method for parsing calibration probe data
 def import_ori(file_path)
     string = IO.read(file_path)
     array = string.split("\n")
     array.delete_if {|x| x[/^Probe*/]}
     return array
 end

 def filterGpr(file_path)
       read = IO.binread(file_path)
       check = read.encode('UTF-8', :invalid => :replace, :undef => :replace)
       File.open(file_path, 'w') { |file| file.write(check) }
 end


#===========================================SEND FILE TO USER=================================================


 #method to download cell counts file in ajax request from the link
 def download_cell_counts     
    file =  Dir.glob("#{Rails.root}/public/Predict/counts/*.csv")[0].to_s
    logger.debug file
    send_file(file)
 end


 #send a sample coeffecients file to the user
 def download_sample_coeffs_file
     temp = [["EukS_1209_25_dT","-178.0129","7310.551","-10963.59"],
["Test15 (EukS_1209_25dT)","-1080.7852","14047.582","-28426.59"],
["EukS_328_25_dT","-274.0996", "6707.7216", "-12045.7096"],
["DinoB_25_dT", "-1164.4423", "7443.100","-12823.424"]]

    send_sample_file("sample_calibration_file", temp)   
 end

 #send a sample raw intensities file to the user
 def download_sample_raw_inten_file
 temp = [["Probe", "Total Intensity"], ["POSITIVE_25_dT", "9.27E+07"], ["Poly-T-CY5", "2.11E+08"], ["EukS_1209_25_dT", "3.21E+08"], ["Test15 (EukS_1209_25dT)", "1.23E+08"]]
 send_sample_file("sample_probe_list", temp)
 end

 #Parent method for sending the sample files to the user.
 def send_sample_file(file_name, arg=[])
     #data = args.join(',').split(',')
     file = CSV.generate do |line|
        arg.each do |element|
        line << element
        end
     end

   send_data(file, 
       :type => 'text/csv;charset=utf-8;header=present', 
       :disposition => "attachment;filename=#{file_name}_#{Time.now.strftime('%d%m%y-%H%M')}.csv")
 end




end



#==========================================EXTRA STUFF==================================================

