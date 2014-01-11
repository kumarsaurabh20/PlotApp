class UploadsController < ApplicationController

 attr_accessor :calib_data, :calib_data_transpose, :calib_probe, :probe_list, :cell_counts, :id
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

     count = 0
     for i in 1..@calib_data_transpose.count
         R.assign "col#{i}", @calib_data_transpose[i-1] 
         count = count + 1 
     end

     cells = @cell_counts.map {|e| e.to_i}

     R.assign "cell_count", cells
     R.assign "calib_probes", @calib_probe
     R.assign "probes", @probe_list
     R.assign "norm_probes", @data
     R.assign "count", count


	cell = R.cell_count
	calib_probe = R.calib_probes
	prober = R.probes
	norm_prober = R.norm_probes
	counter = R.count
	col_1 = R.col1
	col_2 = R.col2
	col_3 = R.col3
	col_4 = R.col4
	col_5 = R.col5

	logger.debug cell.to_s
	logger.debug calib_probe.to_s
	logger.debug prober.to_s
	logger.debug norm_prober.to_s
	logger.debug counter
	logger.debug col_1.to_s
	logger.debug col_2.to_s
	logger.debug col_3.to_s
	logger.debug col_4.to_s
	logger.debug col_5.to_s

     R.eval <<-EOF

    columns <- matrix(0, length(probes), count)

     for (i in c(1:count)) {
         if (i == 1) { columns <- cbind(get(paste0("col",i))) } 
         else { columns <- cbind(columns, get(paste0("col",i))) }    
         }
     
	norm_val <- matrix(0, length(norm_probes), ncol(columns) - 1)

        for (i in 1:length(norm_probes)) {
        dummy <- columns[norm_probes[i] == columns[,1],]
        print(dummy)
        dummy <- dummy[-1]
        print(dummy)
        norm_val[i,] <- dummy
        }

EOF
    
     return R.pull "norm_val"
        
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
        cols = ["Probes", "Intensity with 1ng", "Intensity with 5ng", "Intensity with 50ng", "Intensity with 100ng"]
        row1 = ["cell counts","270","1351","6757","27027"]
        row2 = ["EukS_1209_25_dT","4102788.91290624","1.68E+07","2.62E+08","5.41E+08"]
	row3 = ["Test15 (EukS_1209_25dT)","3242670.65825","1.99E+07","3.92E+08","3.73E+08"]
	row4 = ["EukS_328_25_dT","4564828.4446875","2.18E+07","4.40E+08","6.77E+08"]
	row5 = ["DinoB_25_dT","7269595.08139062","3.56E+07","4.00E+08","6.06E+08"]

        send_file("sample_calibration_file", cols,row1, row2, row3, row4, row5)   
 end

 #send a sample calibration probe file to the user
 def download_sample_probe_list
      header = ["Probes for calibration"]
      row1 = ["EukS_1209_25_dT"]
      row2 = ["EukS_328_25_dT"]
      row3 = ["DinoB_25_dT"]
      row4 = ["Test15 (EukS_1209_25dT)"]

      send_file("sample_probe_list", header,row1, row2, row3, row4)
 end

 #Parent method for sending the sample files to the user.
 def send_file(file_name, *args)
     data = args.join(',').split(',')
     file = CSV.generate do |line|
        args.each do |element|
        line << element
        end
     end

   send_data(file, 
       :type => 'text/csv;charset=utf-8;header=present', 
       :disposition => "attachment;filename=#{file_name}_#{Time.now.strftime('%d%m%y-%H%M')}.csv")
 end

 
end


#cell = R.cell_count
#calib_probe = R.calib_probes
#prober = R.probes
#norm_prober = R.norm_probes
#counter = R.count
#col_1 = R.col1
#col_2 = R.col2
#col_3 = R.col3
#col_4 = R.col4
#col_5 = R.col5
#
#logger.debug cell.to_s
#logger.debug calib_probe.to_s
#logger.debug prober.to_s
#logger.debug norm_prober.to_s
#logger.debug counter
#logger.debug col_1.to_s
#logger.debug col_2.to_s
#logger.debug col_3.to_s
#logger.debug col_4.to_s
#logger.debug col_5.to_s
