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
 
  #directory = "public/"
  #io_calib = params[:upload][:calib]
  #io_inten = params[:upload][:inten]   

  #name_calib = io_calib.original_filename
  #name_inten = io_inten.original_filename
  #calib_path = File.join(directory, "calibs", name_calib)
  #inten_path = File.join(directory, "intens", name_inten)

    respond_to do |format|
      if @upload.save

        @id = @upload.id
        calib_path, inten_path = get_paths(id)
        @calib_data, @calib_data_transpose, @cell_counts = import(calib_path)
        @calib_probe = import_ori(inten_path)       

        #probe list of the uploaded file
        @probe_list = calib_data_transpose[0]
        
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
     
     respond_to do |format|
     format.html { render action: "normalize" }
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

#DIRECTORY = "public/"
#this returns dynamic constant assignment error means  each time you run the method you are assigning  #a new value to the constant. This is not allowed, as it makes the constant non-constant; even though #the contents of the string are the same (for the moment, anyhow), the actual string object itself is #different each time the method is called.

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

#===============================================================================================
#=============================================AJAX ERROR========================================
#===============================================================================================
#this error will come if you dont create a template for mormalize or redirect to appropriate page
#ActionView::MissingTemplate (Missing template uploads/normalize, application/normalize with {:locale=>[:en], :formats=>[:html, :text, :js, :css, :ics, :csv, :png, :jpeg, :gif, :bmp, :tiff, :mpeg, :xml, :rss, :atom, :yaml, :multipart_form, :url_encoded_form, :json, :pdf, :zip], :handlers=>[:erb, :builder, :rabl]}. Searched in:
#  * "/home/jarvis/PlotApp/app/views"
#):
#===============================================================================================


#====================================SEND_FILE_TO_BROWSER=================================================
#There is no send_file :streaming option, it is :stream. You're passing bad parameters types. :buffer_size #should be number, not a string. :stream should be boolean, not string.
#:stream => true,
#:buffer_size => 4096,
#You need only filename parameter (if you want to send file with another name than the original). Other options #you are using are default (except :type).
#Can you try this ?
#@filename ="#{RAILS_ROOT}/tmp/test/test.doc"
#send_file(@filename, :filename => "test.doc")
#==========================================================================================================

#==========================STORING_FILE_IN_DATABASE========================================================
#This is a pretty standard design question, and there isn't really a "one true answer".
#The rule of thumb I typically follow is "data goes in databases, files go in files".
#Some of the considerations to keep in mind:
#If a file is stored in the database, how are you going to serve it out via http? Remember, you need to set the #content type, filename, etc. If it's a file on the filesystem, the web server takes care of all that stuff for #you. Very quickly and efficiently (perhaps even in kernel space), no interpreted code needed.
#Files are typically big. Big databases are certainly viable, but they are slow and inconvenient to back up #etc. Why make your database huge when you don't have to?
#Much like 2., it's really easy to copy files to multiple machines. Say you're running a cluster, you can just #periodically rsync the filesystem from your master machine to your slaves and use standard static http #serving. Obviously databases can be clustered as well, it's just not necessarily as intuitive.
#On the flip side of 3, if you're already clustering your database, then having to deal with clustered files in #addition is administrative complexity. This would be a reason to consider storing files in the DB, I'd say.
#Blob data in databases is typically opaque. You can't filter it, sort by it, or group by it. That lessens the #value of storing it in the database.
#On the flip side, databases understand concurrency. You can use your standard model of transaction isolation #to ensure that two clients don't try to edit the same file at the same time. This might be nice. Not to say #you couldn't use lockfiles, but now you've got two things to understand instead of one.
#Accessibility. Files in a filesystem can be opened with regular tools. Vi, Photoshop, Word, whatever you need. #This can be convenient. How are you gonna open that word document out of a blob field?
#Permissions. Filesystems have permissions, and they can be a pain in the rear. Conversely, they might be #useful to your application. Permissions will really bite you if you're taking advantage of 7, because it's #almost guaranteed that your web server runs with different permissions than your applications.
#Cacheing (from sarah mei below). This plays into the http question above on the client side (are you going to #remember to set lifetimes correctly?). On the server side files on a filesystem are a very well-understood and #optimized access pattern. Large blob fields may or may not be optimized well by your database, and you're #almost guaranteed to have an additional network trip from the database to the web server as well.
#In short, people tend to use filesystems for files because they support file-like idioms the best. There's no #reason you have to do it though, and filesystems are becoming more and more like databases so it wouldn't #surprise me at all to see a complete convergence eventually.
#There's some good advice about using the filesystem for files, but here's something else to think about. If #you are storing sensitive or secure files/attachments, using the DB really is the only way to go. I have built #apps where the data can't be put out on a file. It has to be put into the DB for security reasons. You can't #leave it in a file system for a user on the server/machine to look at or take with them without proper #securty. Using a high-class DB like Oracle, you can lock that data down very tightly and ensure that only #appropriate users have access to that data.
#But the other points made are very valid. If you're simply doing things like avatar images or non-sensitive #info, the filesystem is generally faster and more convenient for most plugin systems.
#The DB is pretty easy to setup for sending files back; it's a little bit more work, but just a few minutes if #you know what you're doing. So yes, the filesystem is the better way to go overall, IMO, but the DB is the #only viable choice when security or sensitive data is a major concern.
#If you use a plugin such as Paperclip, you don't have to worry about anything either. There's this thing #called the filesystem, which is where files should go. Just because it is a bit harder doesn't mean you should #put your files in the wrong place. And with paperclip (or other similar plugins) it isn't hard. So, gogo #filesystem!
#I don't see what the problem with blobstores is. You can always reconstruct a file system store from it, e.g. #by caching the stuff to the local web server while the system is being used. But the authoritative store #should always be the database. Which means you can deploy your application by tossing in the database and #exporting the code from source control. Done. And adding a web server is no issue at all.
#If you are a good programmer you'll never store data on the file system. For that there are blobstores (db). #If you want to make your software scalable you have to use blobstores because your software runs on different #machines. And in worst case your file will be uploaded to the file system on machine #99 and the next request #will be on machine #100 where the file doesn't exists.
#I think at GAE (google app engine): The classes for writing files to file system aren't even enabled.
#=============================================================================================================
