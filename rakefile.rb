desc 'Get event from ATND.'
task :get_event_from_atnd do
  require './lib/get_info'
  require './lib/mongoid'
  require './models/event'
  GetEventFromATND.new
  puts 'done.'
end

desc 'Get event from GoogleCalendar.'
task :get_event_from_google_calendar do
  require 'icalendar'
  require './lib/get_info'
  require './lib/mongoid'
  require './models/event'
#  GetEventFromGoogleCalendar.new
  puts 'it not working.'
end


desc 'Get Info from Facebook.'
task :get_info_from_facebook do
  require './lib/get_info'
  require './lib/mongoid'
  require './models/info'
  GetInfoFromFacebook.new
  puts 'done.'
end
