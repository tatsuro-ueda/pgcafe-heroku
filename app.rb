require 'sinatra'
require 'koala'

require './lib/mongoid'
require './models/info'
require './models/event'

=begin
require 'addressable/uri'
require 'open-uri'
require 'json'
include Addressable
=end

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
set :cache, Dalli::Client.new(ENV["MEMCACHIER_SERVERS"], {username: ENV["MEMCACHIER_USERNAME"], password: ENV["MEMCACHIER_PASSWORD"]})
set :haml, :format => :html5

if ENV['MEMCACHIER_SERVERS']
  use Rack::Cache,
	  verbose:     true,
	  default_ttl: 60 * 60 * 24,
	  metastore:   ENV['MEMCACHIER_SERVERS'] ? "memcached://#{ENV['MEMCACHIER_SERVERS']}/meta" : 'file:tmp/cache/rack/meta',
	  entitystore: ENV['MEMCACHIER_SERVERS'] ? "memcached://#{ENV['MEMCACHIER_SERVERS']}/body" : 'file:tmp/cache/rack/body',
	  allow_reload: false
end

not_found do
  redirect "/"
end

configure do
  set :static_cache_control => [:public, :max_age => 60*60*24]
end

before do

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
    @events ||= settings.cache.fetch("events_#{Date.today.to_s}") do
      events = Event.where(category: 'atnd')
      events = events.sort_by{ |item| item['dtstart'].to_i}
      settings.cache.set("events_#{Date.today.to_s}", events, 60*60*24)
      events
    end
  end
  
  def events_no_cache
    @events = Event.where(category: 'atnd')
  end
  
  def infomation
    @info ||= settings.cache.fetch("info_#{Date.today.to_s}") do
      info = []
      Info.all_of(object: 'link').each_with_index do |item, i|
        info[i/3] = [] if i % 3 == 0
        info[i/3][i%3] = item
      end
      settings.cache.set("info_#{Date.today.to_s}", info, 60*60*24)
      info
    end
  end
end

get "/" do
  cache_control :public, max_age: 60 * 60 * 24
  
  events
  infomation
  
  sass :style
  haml :index 
end

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
