module api
	module v1		
	class ApicallsController < ApplicationController
      
        require 'matrix'
	require 'csv'
        require 'rinruby'
        respond_to :json
        

#method recieving API request from the client 
	def get_coeffecients

		     #ajax request; filter out id from rest of the array/ajax request
		     data = params['data'] 
		    
                     
                 begin

			calib_data = JSON.parse(data, :symbolize_names => true)

			norm_probes = calib_data[:norm_probes]
			calib_data.shift
			calib_probes = calib_data[:calib_probes]
			calib_data.shift
			cell_counts = calib_data[:cell_counts]
			calib_data.shift
                        probe_list = calib_data[:0]
                        calib_data.shift

		     #assign col values to R. Column number is variable here and not fixed in the calibration file
		     count = calib_data.size 
		     calib_data.each do |k,v|
			 R.assign "col#{k}", v.to_a 			  
		     end

		     #map the cells to integer values
		     cells = cell_counts.map {|e| e.to_i}

		     #assign variables to R from Rails
		     R.assign "cells", cells
		     R.assign "calib_probes", calib_probe
		     R.assign "probes", probe_list
		     R.assign "norm_probes", norm_probes
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
		 
		 
		  respond_with @resultsToView
	
		rescue Exception => e
			puts e.to_s + " Error originated in get_coeffecients() method!!"
	        end
		    
	end



	def predict_cell_counts

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
	 
	  
	 respond_with @countToView


	end

	

     end
end
