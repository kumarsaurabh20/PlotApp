class UploadsController < ApplicationController

 attr_accessor :calib_data, :calib_data_transpose, :inten_data, :probe_list
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

#DIRECTORY = "public/"
#this returns dynamic constant assignment error means  each time you run the method you are assigning  #a new value to the constant. This is not allowed, as it makes the constant non-constant; even though #the contents of the string are the same (for the moment, anyhow), the actual string object itself is #different each time the method is called. 

  directory = "public/"
  io_calib = params[:upload][:calib]
  io_inten = params[:upload][:inten]   

  name_calib = io_calib.original_filename
  name_inten = io_inten.original_filename
  calib_path = File.join(directory, "calibs", name_calib)
  inten_path = File.join(directory, "intens", name_inten)

    respond_to do |format|
      if @upload.save
        @calib_data, @calib_data_transpose = import(calib_path)
        @inten_data = import_ori(inten_path)
        #probe list of the uploaded file
        @probe_list = calib_data_transpose[0]
        #logger.debug @probe_list.to_s
        flash[:notice] = "Files were successfully uploaded!!"
        format.html
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
     data = params['data'].split(',') 
     

     R.eval "columns <- matrix()"
     
     for i in 0..@calib_data_transpose.length - 1
         if i == 0
            R.eval "columns <- #{@calib_data_transpose[i]}"
         else
            R.eval "columns <- cbind(columns, #{@calib_data_transpose[i]})"
         end
     end
    
     R.assign "cells", @inten_data
     R.assign "probes", data
     R.eval <<-EOF


   EOF

 end


 #check why its not working with the condition!!! Try to refactor import methods again
 def import(file_path)
     array = import_ori(file_path)
     array_splitted = array.map {|a| a.split(",")} 
     array_transpose = array_splitted.transpose
   return array_splitted, array_transpose
 end
 
 def import_ori(file_path)
     string = IO.read(file_path)
     array = string.split("\n")
     array.shift
     return array
 end

 def download_sample_calib_file	
        cols = ["Probes", "Intensity with 1ng", "Intensity with 5ng", "Intensity with 50ng", "Intensity with 100ng"]
        row1 = ["EukS_1209_25_dT","4102788.91290624","1.68E+07","2.62E+08","5.41E+08"]
	row2 = ["Test15 (EukS_1209_25dT)","3242670.65825","1.99E+07","3.92E+08","3.73E+08"]
	row3 = ["EukS_328_25_dT","4564828.4446875","2.18E+07","4.40E+08","6.77E+08"]
	row4 = ["DinoB_25_dT","7269595.08139062","3.56E+07","4.00E+08","6.06E+08"]

        send_file("sample_calibration_file", cols,row1, row2, row3, row4)   
 end

 def download_sample_cell_count_file
      header = ["Cell Count"]
      row1 = ["270"]
      row2 = ["1351"]
      row3 = ["6757"]
      row4 = ["27027"]

      send_file("sample_cell_count_file", header,row1, row2, row3, row4)
 end

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
