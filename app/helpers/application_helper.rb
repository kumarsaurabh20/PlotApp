module ApplicationHelper

# Methods added to this helper will be available to all templates in the application.
#set R_HOME if not set

	 if ENV['R_HOME'].nil?
	     ENV['R_HOME'] = "/usr/lib/R"
	 end



# Return a title on a per-page basis.
  def title
    base_title = "S2C"
    if @title.nil?
      base_title
    else
      # user could enter a name with malicious code—called a cross-site scripting attack
      #The solution is to escape potentially problematic code using the h method (short for html_escape)
      "#{base_title} | #{(@title)}"
    end
  end

  #LOGO
  def appHelperLogo
    #image_tag("logo.png", :alt => "Sample App", :class => "round")
    image_tag("uaqua1_logo2.png", :alt => "S2C", :class => "round", :size => "100x75")
  end

 

 def uploadLogo
     image_tag("upload.gif", :alt => "upload", :class => "round", :size => "150x150")
 end

 def upload2Logo
     image_tag("upload2.gif", :alt => "upload", :class => "round", :size => "100x75")
 end

 #LOGO
  def appUnicamLogo
    image_tag("unicamit.jpg", :alt => "S2C", :class => "round", :size => "100x75")
  end

  #BETA
  def appGithubLogo
    image_tag("github.jpg", :title => "Development version", :alt => "Development version", :class => "round", :size => "190x75")
  end

 #contacts
  def appContactLogo
    image_tag("contacts.jpg", :title => "Development version", :alt => "Development version", :class => "round", :size => "70x50")
  end

end
