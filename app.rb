require 'sinatra'
require 'koala'

require './lib/mongoid'
require './models/info'
require './models/event'

require 'addressable/uri'
require 'open-uri'
require 'json'
include Addressable

# require 'icalendar'

=begin
require './lib/image_uploader'
require './models/user'

require './lib/serve_gridfs_image'

use Rack::Lint
use ServeGridfsImage
=end

enable :sessions
set :raise_errors, false
set :show_exceptions, false
set :cache, Dalli::Client.new
set :haml, :format => :html5

if ENV['MEMCACHIER_SERVERS']
  use Rack::Cache,
    verbose:     true,
    default_ttl: 60 * 60,
    metastore:   Dalli::Client.new,
    entitystore: ENV['MEMCACHIER_SERVERS'] ? "memcached://#{ENV['MEMCACHIER_SERVERS']}/body" : 'file:tmp/cache/rack/body',
    allow_reload: false
end

not_found do
  redirect "/"
end

configure do
  set :static_cache_control => [:public, :max_age => 60*60*24*30]
  # load File.expand_path('../lib/mongoid.rb', __FILE__)
  # load File.expand_path('../lib/carrierwave.rb', __FILE__)
end

before do
  # HTTPS redirect
  if settings.environment == :production && request.scheme != 'https'
    redirect "https://#{request.env['HTTP_HOST']}"
  end
=begin
  unless session[:date]
    session[:date] = Date.today
  end
  @date = session[:date]
  @wdays = ['日','月','火','水','木','金','土']
=end
end

helpers do
  def host
    request.env['HTTP_HOST']
  end

  def scheme
    request.scheme
  end

  def url_no_scheme(path = '')
    "//#{host}#{path}"
  end

  def url(path = '')
    "#{scheme}://#{host}#{path}"
  end
  
  def events
    events = Event.where(:category => 'atnd')
    @events = events.sort_by{ |item| item['dtstart'].to_i }
  end
  
  def search_all
    @info = []
    Info.all_of(object: 'link').each_with_index do |info, i|
      @info[i/3] = [] if i % 3 == 0
      @info[i/3][i%3] = info
    end
    
=begin
    Event.all_of(category: 'google').each do |event|
      p rrule = event.rrule.scan(/(\w+)\=([\w,]+)/)
      case rrule.assoc("FREQ")[1]
      when "WEEKLY"
        rrule.assoc("UNTIL")
      end
    end
=end
=begin
      p event.name
      p event.description
      p event.dtstart
      p event.dtend
      p event.rrule.scan(/(\w+)\=([\w,]+)/)
=end
  end
  
  def get_google_calendar
    url = "https://www.google.com/calendar/ical/mroq255j953tfk6jsu2gf77trk%40group.calendar.google.com/public/basic.ics"
    uri = URI.parse(url)
    ical = open(uri).read
    cal = Icalendar.parse(ical, true)
    cal.events.each do |event|
      p event.summary
      p event.dtstart
      p event.dtend
      p event.description
      r = ""
      event.recurrence_rules.map do |rule|
        p rule.orig_value.scan(/(\w+)\=([\w,]+)/)
        r << rule.orig_value.to_s
      end
    end
  end
end

get "/" do
  events
  search_all
#  get_google_calendar
  
  sass :style
  haml :index 
end

# used by Canvas apps - redirect the POST to be a regular GET
post "/" do
  redirect "/"
end

get '/index.html' do
  haml :index
end

get '/style.css' do
  sass :style
end

=begin
get '/daleteall' do
  Event.destroy_all
#  Info.destroy_all
  redirect '/'
end
=end
