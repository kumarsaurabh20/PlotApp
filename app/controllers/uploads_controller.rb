class UploadsController < ApplicationController

require 'csv'


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
        flash[:notice] = "Files were successfully uploaded!!"
        format.html { redirect_to uploads_url }
        format.json { render json: @upload, status: :created, location: @upload }
      else
        format.html { render action: "new" }
        format.json { render json: @upload.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /uploads/1
  # DELETE /uploads/1.json
  def destroy
    @upload = Upload.find(params[:id])
    @upload.destroy

    respond_to do |format|
      format.html { redirect_to uploads_url }
      format.json { head :no_content }
    end
  end

  def download_sample_calib_file
	file = CSV.generate do |line|
        cols = ["Probes", "Intensity with 1ng", "Intensity with 5ng", "Intensity with 50ng", "Intensity with 100ng"]
        row1 = ["EukS_1209_25_dT","4102788.91290624","1.68E+07","2.62E+08","5.41E+08"]
	row2 = ["Test15 (EukS_1209_25dT)","3242670.65825","1.99E+07","3.92E+08","3.73E+08"]
	row3 = ["EukS_328_25_dT","4564828.4446875","2.18E+07","4.40E+08","6.77E+08"]
	row4 = ["DinoB_25_dT","7269595.08139062","3.56E+07","4.00E+08","6.06E+08"]

        line << cols
        line << row1
        line << row2
        line << row3
        line << row4

	end
 
      send_data(file, 
       :type => 'text/csv;charset=utf-8;header=present', 
       :disposition => "attachment;filename=Sample_calibration_data_#{Time.now.strftime('%d%m%y-%H%M')}.csv")	
    
  end

  def download_sample_cell_count_file

      file = CSV.generate do |line|
      line << ["Cell Count"]
      line << ["270"]
      line << ["1351"]
      line << ["6757"]
      line << ["27027"]
     end
  
    send_data(file, 
       :type => 'text/csv;charset=utf-8;header=present', 
       :disposition => "attachment;filename=Sample_cell_count_data_#{Time.now.strftime('%d%m%y-%H%M')}.csv")
      

  end

  





end
