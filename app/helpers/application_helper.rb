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
    image_tag("uaqua1_logo2.png", :alt => "S2C", :class => "round", :size => "100x69")
  end

  #BETA
  def appBetaLogo
    image_tag("icon_beta3.jpg", :title => "Development version", :alt => "Development version", :class => "round", :size => "69x69")
  end


end
