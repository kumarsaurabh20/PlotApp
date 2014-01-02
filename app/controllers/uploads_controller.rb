class UploadsController < ApplicationController


 attr_accessor :calib_data, :calib_data_transpose, :calib_probe, :probe_list, :cell_counts, :id, :result


  # GET /uploads
  # GET /uploads.json
  def index
    @uploads = Upload.all
    
    @upload = Upload.new
   
    respond_to do |format|
      format.html 
      format.json { render json: @uploads }   
    end
  end

  # POST /uploads
  # POST /uploads.json
 def create
  @upload = Upload.new(params[:upload]) 

    respond_to do |format|
      if @upload.save

        @id = @upload.id
        calib_path, inten_path = get_paths(id)
        @calib_data, @calib_data_transpose, @cell_counts = import(calib_path)
        @calib_probe = import_ori(inten_path)       

        #probe list of the uploaded file
        @probe_list = calib_data_transpose[0]
        
        flash[:notice] = "Files were successfully uploaded!!"
        format.html { render "normalize" }
        #format.js #{ render json: @upload, status: :created, location: @upload }
      else
        flash[:notice] = "Error in uploading!!"
        format.html { render action: "index" }
        format.json { render json: @upload.errors, status: :unprocessable_entity }
      end
    end
 end


#method recieving Ajax request from the view posting selected probes for normalization
def normalize
     #logger.debug @cell_counts.to_s

     #ajax request; filter out id from rest of the array/ajax request
     @data = params['data'].split(',') 
     id = @data.shift

     #fetch saved file paths
     calib_path, inten_path = get_paths(id)
     
     #file data in R input compatible format
     @calib_data, @calib_data_transpose, @cell_counts = import(calib_path)
     @calib_probe = import_ori(inten_path)      

     #probe list of the uploaded file
     @probe_list = calib_data_transpose[0]

     #assign col values to R. Column number is variable here and not fixed in the calibration file
     count = 0
     for i in 1..@calib_data_transpose.count
         R.assign "col#{i}", @calib_data_transpose[i-1] 
         count = count + 1 
     end

     #map the cells to integer values
     cells = @cell_counts.map {|e| e.to_i}

     #assign variables to R from Rails
     R.assign "cells", cells
     R.assign "calib_probes", @calib_probe
     R.assign "probes", @probe_list
     R.assign "norm_probes", @data
     R.assign "count", count

     #Block of R code to be executed
     R.eval <<-EOF

     columns <- matrix(0, length(probes), count)

     for (i in c(1:count)) {
         if (i == 1) { columns <- cbind(get(paste0("col",i))) } 
         else { columns <- cbind(columns, get(paste0("col",i))) }    
         }
     
	norm_val <- matrix(0, length(norm_probes), ncol(columns) - 1)

        for (i in 1:length(norm_probes)) {
        dummy <- columns[norm_probes[i] == columns[,1]]
        print(dummy)
        dummy <- dummy[-1]
        norm_val[i,] <- dummy
        }

  column_filter <- columns[, -1]
  col <- ncol(column_filter)
  row <- nrow(column_filter)
  tab_norm_1 <- matrix(0, row,col)
  t_tab_norm_1 <- matrix(0, col,row)
  tab_norm_2 <- matrix(0, row,col)
  t_tab_norm_2 <- matrix(0, col,row)
  tab_norm_3 <- matrix(0, row,col)
  t_tab_norm_3 <- matrix(0, col,row)
  tab_norm_4 <- matrix(0, row,col)
  t_tab_norm_4 <- matrix(0, col,row)
  tab_norm_5 <- matrix(0, row,col)
  t_tab_norm_5 <- matrix(0, col,row)
  tab_norm_6 <- matrix(0, row,col)
  t_tab_norm_6 <- matrix(0, col,row)
  myData <- list()


  if (length(norm_probes) == 2) {
	for(i in c(1:ncol(norm_val))) {tab_norm_1[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[1,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_2[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[2,i])}))}
t_tab_norm_1 <- t(tab_norm_1)
t_tab_norm_2 <- t(tab_norm_2)
for (i in c(1:ncol(t_tab_norm_1))) {myData[[i]] <- cbind(cells, t_tab_norm_1[,i], t_tab_norm_2[,i])}
} else if (length(norm_probes) == 3) {
	for(i in c(1:ncol(norm_val))) {tab_norm_1[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[1,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_2[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[2,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_3[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[3,i])}))}
t_tab_norm_1 <- t(tab_norm_1)
t_tab_norm_2 <- t(tab_norm_2)
t_tab_norm_3 <- t(tab_norm_3)
for (i in c(1:ncol(t_tab_norm_1))) {myData[[i]] <- cbind(cells, t_tab_norm_1[,i], t_tab_norm_2[,i], t_tab_norm_3[,i])}
} else if (length(norm_probes) == 4) {
	for(i in c(1:ncol(norm_val))) {tab_norm_1[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[1,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_2[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[2,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_3[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[3,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_4[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[4,i])}))}
t_tab_norm_1 <- t(tab_norm_1)
t_tab_norm_2 <- t(tab_norm_2)
t_tab_norm_3 <- t(tab_norm_3)
t_tab_norm_4 <- t(tab_norm_4)
for (i in c(1:ncol(t_tab_norm_1))) {myData[[i]] <- cbind(cells, t_tab_norm_1[,i], t_tab_norm_2[,i], t_tab_norm_3[,i], t_tab_norm_4[,i])}
} else if (length(norm_probes) == 5) {
	for(i in c(1:ncol(norm_val))) {tab_norm_1[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[1,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_2[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[2,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_3[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[3,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_4[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[4,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_5[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[5,i])}))}
t_tab_norm_1 <- t(tab_norm_1)
t_tab_norm_2 <- t(tab_norm_2)
t_tab_norm_3 <- t(tab_norm_3)
t_tab_norm_4 <- t(tab_norm_4)
t_tab_norm_5 <- t(tab_norm_5)
for (i in c(1:ncol(t_tab_norm_1))) {myData[[i]] <- cbind(cells, t_tab_norm_1[,i], t_tab_norm_2[,i], t_tab_norm_3[,i], t_tab_norm_4[,i], t_tab_norm_5[,i])}
} else if (length(norm_probes) == 6) {
	for(i in c(1:ncol(norm_val))) {tab_norm_1[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[1,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_2[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[2,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_3[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[3,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_4[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[4,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_5[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[5,i])}))}
	for(i in c(1:ncol(norm_val))) {tab_norm_6[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[6,i])}))}
t_tab_norm_1 <- t(tab_norm_1)
t_tab_norm_2 <- t(tab_norm_2)
t_tab_norm_3 <- t(tab_norm_3)
t_tab_norm_4 <- t(tab_norm_4)
t_tab_norm_5 <- t(tab_norm_5)
t_tab_norm_6 <- t(tab_norm_6)
for (i in c(1:ncol(t_tab_norm_1))) {myData[[i]] <- cbind(cells, t_tab_norm_1[,i], t_tab_norm_2[,i], t_tab_norm_3[,i], t_tab_norm_4[,i], t_tab_norm_5[,i], t_tab_norm_5[,i])}
} else {for(i in c(1:ncol(norm_val))) {tab_norm_1[,i] <- unlist(lapply(as.numeric(column_filter[,i]), function(x) {x/as.numeric(norm_val[1,i])}))}
t_tab_norm_1 <- t(tab_norm_1)
for (i in c(1:ncol(t_tab_norm_1))) {myData[[i]] <- cbind(cells, t_tab_norm_1[,i])}
}



calLinMod <- function(x) {
            x <- as.matrix(x)
            if (ncol(x) == 2) {fit <- lm(x[,1] ~ x[,2])}
            if (ncol(x) == 3) {fit <- lm(x[,1] ~ x[,2] + x[,3])}
            if (ncol(x) == 4) {fit <- lm(x[,1] ~ x[,2] + x[,3] + x[,4])}
            if (ncol(x) == 5) {fit <- lm(x[,1] ~ x[,2] + x[,3] + x[,4] + x[,5])}
            if (ncol(x) == 6) {fit <- lm(x[,1] ~ x[,2] + x[,3] + x[,4] + x[,5] + x[,6])}
            if (ncol(x) == 7) {fit <- lm(x[,1] ~ x[,2] + x[,3] + x[,4] + x[,5] + x[,6] + x[,7])}
            return(as.numeric(coef(fit)))
       }

 fitted_coeffs <- sapply(myData, calLinMod)
 coeffs_matrix <- matrix(fitted_coeffs, nrow(columns), length(norm_probes) + 1, byrow = T)
 probe_list <- columns[, 1]
 result_matrix <- cbind(probe_list, coeffs_matrix)

 selectProbeFromList <- function(result_matrix, calib_probes) {

 commonProbesInTwoResults <- intersect(as.vector(result_matrix[,1]), calib_probes)
 selectedProbesFromGpr <- matrix(0, length(commonProbesInTwoResults), ncol(result_matrix))
  
  for (i in c(1:length(commonProbesInTwoResults))) {
  selectedProbesFromGpr[i,] <- subset(result_matrix, commonProbesInTwoResults[i] == result_matrix[ , 1])
  }

return(selectedProbesFromGpr)

}

 results <- selectProbeFromList(result_matrix, calib_probes)



EOF

  #pull the resultant coeffecients matris
  @result = R.pull "results"
  @resultsToView = Array.new
  for i in 0..@result.row_size
   	@resultsToView.push(@result.row(i).to_a)
  end
  #remove the last empty array from the matrix
  @resultsToView.pop
  #count the total number of vectors in the matrix
  @totalSize = @resultsToView.size
  #count total number of elements in the matrix, useful for counting <td> elements in the view
  @columnSize = @resultsToView[1].size
 
  
 #export a csv file containing coeffecients and keep it in public folder.
 
     #provide a name to the file having individual calibration ID
     namefile = Time.now.strftime("%Y%m%d%H%M%S_") + "coeffs_file" + "_" + id + ".csv"

     #remove all previous csv coeffecients files
     #user have to caluclate coeffecients multiple times before performing prediction so its good
     #to delete all previous coeffs file and deal with the present
     FileUtils.rm_rf Dir.glob('#{Rails.root}/public/coeffs/*') unless !Dir['#{Rails.root}/public/coeffs/*'].empty?
    
     #create a coeff directory in public folder of rails 
     coeff_path = "#{Rails.root}/public/coeffs"
     Dir.mkdir(coeff_path) unless File.directory?(coeff_path)
 
     #create a file path
     path = File.join(coeff_path, namefile)

  
     #call CSV class and open a new csv file 
     CSV.open(path, 'wb') do |csv|
         #use matrix class of ruby and check the row size of returned matrix.
         row_count = @result.row_size
         for i in 0..row_count         
         #extract individual row of matrix as vector and convert it to array and push it to csv line
		 csv << @result.row(i).to_a
	     end
     end

      
     respond_to do |format|
     format.html { render "normalize" }
     format.js     
     end 
    
 end


 #method for fetching saved file path based on retrived upload ID from database
 #ID is required to fetch session specific file.
 def get_paths(id)
     #use ID argument to fetch that particular record.
     #with the help of id fetch the file names from database
     upload = Upload.find(id)
     calib_file_name = upload.calib_file_name
     inten_file_name = upload.inten_file_name

     #set the path to the file folder
     calib_path = "#{Rails.root}/public/calibs"
     inten_path = "#{Rails.root}/public/intens"
      
     #create file paths and return them    
     calib_file = File.join(calib_path, calib_file_name)
     inten_file = File.join(inten_path, inten_file_name)
 
     return calib_file, inten_file
 end


 #method for parsing calibration data
 #check why its not working with the condition!!! Try to refactor import methods again
 def import(file_path)
     array = import_ori(file_path)
     counts = array.shift
     cell_counts = get_cell_counts(counts)
     array_splitted = array.map {|a| a.split(",")} 
     array_transpose = array_splitted.transpose
     return array_splitted, array_transpose, cell_counts
 end
 
 #method for parsing calibration probe data
 def import_ori(file_path)
     string = IO.read(file_path)
     array = string.split("\n")
     array.shift
     return array
 end

 #method for parsing cell counts in the calibration file separately
 def get_cell_counts(array="")
     cell_counts = array.split(",")
     cell_counts.shift
     return cell_counts
 end

 #send a sample calibration file to the user
 def download_sample_calib_file	
     temp = [["Probes", "Intensity with 1ng", "Intensity with 5ng", "Intensity with 50ng", "Intensity with 100ng"], ["cell counts","270","1351","6757","27027"], ["EukS_1209_25_dT","4102788.91290624","1.68E+07","2.62E+08","5.41E+08"], ["Test15 (EukS_1209_25dT)","3242670.65825","1.99E+07","3.92E+08","3.73E+08"],["EukS_328_25_dT","4564828.4446875","2.18E+07","4.40E+08","6.77E+08"], ["DinoB_25_dT","7269595.08139062","3.56E+07","4.00E+08","6.06E+08"]]

     send_file("sample_calibration_file", temp)   
 end

 #send a sample calibration probe file to the user
 def download_sample_probe_list
 temp = [["Probes for calibration"], ["EukS_1209_25_dT"], ["EukS_328_25_dT"], ["DinoB_25_dT"], ["Test1 (EukS_1209_25dT)"]]
 send_file("sample_probe_list", temp)
 end

 #Parent method for sending the sample files to the user.
 def send_file(file_name, arg=[])
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
