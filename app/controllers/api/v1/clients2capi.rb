class Clients2capi

require 'rest_client'
require 'json'

 def api_hook(method_name = "", params)

	 # base url of the API
	 API_BASE_URL = "http://localhost:3000/api" 

	 # specifying json format in the URl
	 uri = "#{API_BASE_URL}/#{method_name}" 

	 # converting the params to json
	 payload = params.to_json 

	 # It will createnew rest-client resource so that we can call different methods of it
	 rest_resource = RestClient::Resource.new(uri)

	  begin
	      results = rest_resource.post payload , :content_type => "application/json"    
	  rescue Exception => e
	      e.response
	  end 

	 # we will convert the return data into array of hash.see json data parsing here
	 @data = JSON.parse(results, :symbolize_names => true) 

 end


 def format_data


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

    

    
    
 
