R implementation testing on rails 3.2.13 and 1.9.3 ruby with RinRuby

A prerequisite for RinRuby is a working installation of R:

   $ gem install rinruby

Regardless of the installation method, RinRuby is invoked within a Ruby/in rails controllers script (or the interactive "irb" prompt denoted >>) using:
  
   require "rinruby"

The app utilizes google javascript/jquery charting library to create dynamic graphs.


