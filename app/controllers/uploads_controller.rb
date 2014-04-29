class UploadsController < ApplicationController

 attr_accessor :calib_data, :calib_data_transpose, :calib_probe, :probe_list, :cell_counts
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
        @calib_data, @calib_data_transpose, @cell_counts = import(calib_path)
        @calib_probe = import_ori(inten_path)
        logger.debug @calib_data.to_s 
        logger.debug @calib_data_transpose.to_s
        logger.debug @cell_counts.to_s        

        #probe list of the uploaded file
        @probe_list = calib_data_transpose[0]
        logger.debug @probe_list.to_s

        logger.debug @calib_probe.to_s
        
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

#I cant access some instance variables from create actions for passing uploaded file data.
#http://billpatrianakos.me/blog/2013/10/14/api-sessions-with-redis-in-rails/
# https://www.ruby-forum.com/topic/4289725
#Instance variables in Rails controllers are only shared for a request -response cycle. Ie, you cannot access variables set in the show action from the onepage action. You will need to reinitialise them. If you want to keep things DRY, put it in a before filter.
#eg:
#class onepages_controller
#  before_filter :filter_name
#  def show
#    render 'onepages/onepage'
#  end
#
#  def onepage
#
#  // have to access show method variables
#  end
#
#  protected
#
#  def filter_name
#    @name = "name1"
#  end
#
#end
#You will now have @name in both show and onepage.

# To use above code I need to store file path some where. Global variable is not recommended, so I need to store path either in the data base or need to use session/cookies. So search also showed me the possibility of using Redis. check out the following links:
#http://blog.bigbinary.com/2013/03/19/cookies-on-rails.html
#http://billpatrianakos.me/blog/2013/10/14/api-sessions-with-redis-in-rails/
#http://dev.housetrip.com/2014/01/14/session-store-and-security/
#http://wonko.com/post/why-you-probably-shouldnt-use-cookies-to-store-session-data
#what if user disable the cookies... rails can not use sessions without cookie
#http://stackoverflow.com/questions/7267381/storing-data-if-cookies-are-disabled-in-browser
#saving path in database looks feasible to me but some concerns in case of Restful APIs
#http://www.tutorialspoint.com/ruby-on-rails/rails-session-cookies.htm
#http://stevenyue.com/2013/07/04/sharing-sessions-and-authentication-between-rails-and-node-js-using-redis/
#http://pothibo.com/2013/09/sessions-and-cookies-in-ruby-on-rails/
#what we can do is create a hidden field in the create view with the saving file ID..and pass that ID along with probe names via AJAx and then in normalize method retrieve the id and file names from the database and perform the opperations. 

#answer to this:
#http://stackoverflow.com/questions/19526205/instance-variables-through-methods-in-ruby-on-rails

     @data = params['data'].split(',')
 
     logger.debug @data.to_s
     logger.debug @calib_data.to_s
     logger.debug @calib_data_transpose.to_s
     logger.debug @cell_counts	.to_s

     
     render action: "normalize" 

#===============================================================================================
#=============================================AJAX ERROR========================================
#===============================================================================================
#this error will come if you dont create a template for mormalize or redirect to appropriate page
#ActionView::MissingTemplate (Missing template uploads/normalize, application/normalize with {:locale=>[:en], :formats=>[:html, :text, :js, :css, :ics, :csv, :png, :jpeg, :gif, :bmp, :tiff, :mpeg, :xml, :rss, :atom, :yaml, :multipart_form, :url_encoded_form, :json, :pdf, :zip], :handlers=>[:erb, :builder, :rabl]}. Searched in:
#  * "/home/jarvis/PlotApp/app/views"
#):
#===============================================================================================

     
 end














 #check why its not working with the condition!!! Try to refactor import methods again
 def import(file_path)
     array = import_ori(file_path)
     counts = array.shift
     cell_counts = get_cell_counts(counts)
     array_splitted = array.map {|a| a.split(",")} 
     array_transpose = array_splitted.transpose
     return array_splitted, array_transpose, cell_counts
 end
 
 def import_ori(file_path)
     string = IO.read(file_path)
     array = string.split("\n")
     array.shift
     return array
 end

 def get_cell_counts(array="")
     cell_counts = array.split(",")
     cell_counts.shift
     return cell_counts
 end

 def download_sample_calib_file	
        cols = ["Probes", "Intensity with 1ng", "Intensity with 5ng", "Intensity with 50ng", "Intensity with 100ng"]
        row1 = ["cell counts","270","1351","6757","27027"]
        row2 = ["EukS_1209_25_dT","4102788.91290624","1.68E+07","2.62E+08","5.41E+08"]
	row3 = ["Test15 (EukS_1209_25dT)","3242670.65825","1.99E+07","3.92E+08","3.73E+08"]
	row4 = ["EukS_328_25_dT","4564828.4446875","2.18E+07","4.40E+08","6.77E+08"]
	row5 = ["DinoB_25_dT","7269595.08139062","3.56E+07","4.00E+08","6.06E+08"]

        send_file("sample_calibration_file", cols,row1, row2, row3, row4, row5)   
 end

 def download_sample_probe_list
      header = ["Probes for calibration"]
      row1 = ["EukS_1209_25_dT"]
      row2 = ["EukS_328_25_dT"]
      row3 = ["DinoB_25_dT"]
      row4 = ["Test15 (EukS_1209_25dT)"]

      send_file("sample_probe_list", header,row1, row2, row3, row4)
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
