class PredictsController < ApplicationController

attr_accessor :raw_inten_transpose, :coeffs_transpose, :probe_list, :id

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
        @coeffs_transpose = import(coeffs_path)
        @probe_list = @raw_inten_transpose[0]

        flash[:notice] = "Files were successfully uploaded!!"
        format.html { render "calculate" }
      else
        format.html { render action: "new" }
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

     #fetch saved file paths
     coeffs_path, rawintens_path = get_paths(id)
     
     #file data in R input compatible format (currently its 2D array as row vectors)
     @coeffs_data_transpose = import(coeffs_path)
     @raw_inten_data = import(rawintens_path)

     return @coeffs_data_transpose
      
     respond_to do |format|
     format.html { render "calculate" }
     format.js     
     end 


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
     array = import_ori(file_path)
     array_splitted = array.map {|a| a.split(",")} 
     array_transpose = array_splitted.transpose
     return array_transpose
 end
 
 #method for parsing calibration probe data
 def import_ori(file_path)
     string = IO.read(file_path)
     array = string.split("\n")
     array.delete_if {|x| x[/^Probe*/]}
     return array
 end


#===========================================SEND FILE TO USER=================================================


 #method to download cell counts file in ajax request from the link
 def download_cell_counts     
    file =  Dir.glob("#{Rails.root}/public/Predict/cellCounts/*.csv")[0].to_s
    logger.debug file
    send_file(file)
 end


 #send a sample coeffecients file to the user
 def download_sample_coeffs_file	
     temp = [["Probes", "Intensity with 1ng", "Intensity with 5ng", "Intensity with 50ng", "Intensity with 100ng"], ["cell counts","270","1351","6757","27027"], ["EukS_1209_25_dT","4102788.91290624","1.68E+07","2.62E+08","5.41E+08"], ["Test15 (EukS_1209_25dT)","3242670.65825","1.99E+07","3.92E+08","3.73E+08"],["EukS_328_25_dT","4564828.4446875","2.18E+07","4.40E+08","6.77E+08"], ["DinoB_25_dT","7269595.08139062","3.56E+07","4.00E+08","6.06E+08"]]

     send_sample_file("sample_calibration_file", temp)   
 end

 #send a sample raw intensities file to the user
 def download_sample_raw_inten_file
 temp = [["Probes for calibration"], ["EukS_1209_25_dT"], ["EukS_328_25_dT"], ["DinoB_25_dT"], ["Test1 (EukS_1209_25dT)"]]
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
