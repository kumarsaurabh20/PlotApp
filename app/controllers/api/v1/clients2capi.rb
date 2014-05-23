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
#Basic Authentication:
#    username: myfinance
#    password: credit123

#Content Type :
#   application/xml or application/json
#
#Body:
#   You can pass xml or json data in Body
#   
#   sample json body
#
#   {
#     "email" : "test@yopmail.com", 
#     "first_name" : "arun", 
#     "last_name" : "yadav"
#    }
#
#   Sample xml body
#
#    <user>
#      <email>"test@yopmail.com">
#      <first-name>arun</first-name>
#      <last-name>yadav</last-name>
#    </user>

#NOTE : Content Type should be set to application/xml for xml data in body 
#and to application/json for json data in body
#
#API Requests:
#
#=> listing users
#   url: http://localhost:3000/api/users
#   method: GET
#   body : not needed
#
#=> Retrieving User detail
#  url: http://localhost:3000/api/users/:id 
#  method: GET
#  body : not needed
#
#=> creating users
#   url: http://localhost:3000/api/users
#   method: Post
#   Body : It can be xml or json
#
#=> Updating User
#  url: http://localhost:3000/api/users/:id 
#  method: PUT
#  Body : It can be xml or json
#  
#=> Deleting User 
#  url: http://localhost:3000/api/users/:id 
#  method: DELETE
#  body : not needed

    

    
    
 
