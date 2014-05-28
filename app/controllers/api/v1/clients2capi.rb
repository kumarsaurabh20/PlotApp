class Clients2capi

require 'rubygems'
require 'rest_client'
require 'json'

 def api_hook

	 # base url of the API
	 API_BASE_URL = "http://localhost:3000/api/v1" 

	 # specifying json format in the URl
	 uri = "#{API_BASE_URL}/#{method_name}" 

	 # convert the file data in to json string
	 payload = read_data_to_json('api_calib_file.csv')
         

	 # It will createnew rest-client resource so that we can call different methods of it
	 rest_resource = RestClient::Resource.new(uri)

	  begin
	      results = rest_resource.post payload , :content_type => "application/json"    
	  rescue Exception => e
	      e.response
	  end 

	 # we will convert the return data into array of hash.see json data parsing here
	 @data = JSON.parse(results, :symbolize_names => true) 

         #write the resultant data in a neat json format
         #File.open('output.json', 'w') {|file| file.write(JSON.pretty_generate(payload))}

 end


 def read_data_to_json(file_name)
          hash_data = Hash.new {|hash, key| hash[key] = []}
        
          data_string = IO.read(file_name)
          data_array = data_string.split("\n")
          
          norm_probes = format_data(data_array)
          hash_data['norm_probes'] = norm_probes
                  
          calib_probes = format_data(data_array)
          hash_data['calib_probes'] = calib_probes
                           
          #remove headers
          data_array.shift
          
          cell_counts = data_array.shift
          cell_counts = cell_counts.split(",")
          cell_counts.shift
          hash_data['cell_counts'] = cell_counts
          
          signal_data= data_array.map {|a| a.split(",")}
          signal_data_transpose = signal_data.transpose
                    
          for i in 0..signal_data_transpose.size - 1 
              hash_data[i] << signal_data_transpose[i]
          end

          return hash_data.to_json          
 end

 
 def format_data(data_array = [])     
     popped_list = data_array.pop
     splitted_list = popped_list.split(',')
     splitted_list.shift
     return splitted_list
 end


end  


######################################STEP:CREATING API DOCUMENTATION######################################
#==========================================================================================================
#Your API is ready with step 3, but how other people will use it. You need to tell them, how to use it. Let #us Document the things
#API USAGE DOCUMENT
#___________________________________________________________________
#Basic Authentication: nil
#   
#Content Type :
#   application/json
#
#Body:
#   You can pass json data
#   
#   sample json body
#
#   {
#     "email" : "test@test.com", 
#     "first_name" : "xxxx", 
#     "last_name" : "xxxx"
#    }
#
# 
#NOTE : Content Type should be set to application/json
#
#API Requests:
#
#=> getting coeffecients values for selected probes
#   url: http://localhost:3000/api/v1/get_coeffecients
#   method: POST
#   body : not needed
#
#=> Predicting cell counts for the raw intensity data
#  url: http://localhost:3000/api/v1/predict_cell_counts
#  method: POST
#  body : not needed
#
#

    

    
    
 
