require 'sinatra'
require 'koala'

require './lib/mongoid'
require './models/facebook'
require './models/event'

=begin
require 'addressable/uri'
require 'open-uri'
require 'json'
include Addressable
=end

=begin
require './lib/image_uploader'

require './lib/serve_gridfs_image'

use Rack::Lint
use ServeGridfsImage
=end

// セッション管理
enable :sessions

set :raise_errors, false
set :show_exceptions, false
set :cache, Dalli::Client.new(ENV["MEMCACHE_SERVERS"], {username: ENV["MEMCACHE_USERNAME"], password: ENV["MEMCACHE_PASSWORD"]})
set :haml, :format => :html5

if ENV['MEMCACHIER_SERVERS']
  use Rack::Cache,
    verbose: true,
    default_ttl: 60*60*12,
    metastore: ENV['MEMCACHE_SERVERS'] ? "memcached://#{ENV['MEMCACHE_SERVERS']}/meta" : 'file:tmp/cache/rack/meta',
    entitystore: ENV['MEMCACHE_SERVERS'] ? "memcached://#{ENV['MEMCACHE_SERVERS']}/body" : 'file:tmp/cache/rack/body',
    allow_reload: false
end

// 宛先のないリクエストはルートへ
not_found do
  redirect "/"
end

configure do
  set :static_cache_control => [:public, :max_age => 60*60*24]
end

before do

end

helpers do
  // ATND関係のキャッシュがあれば、それを使う
  def events
    @events ||= settings.cache.fetch("events_#{Time.now.strftime('%Y-%m-%d')}") do
      events = Event.where(category: 'atnd')
      events = events.sort_by{ |item| item['dtstart'].to_i}
      settings.cache.set("events_#{Time.now.strftime('%Y-%m-%d')}", events, 60*60*24)
      events
    end
  end
  
  // キャッシュがなければ新規で呼ぶ
  def events_no_cache
    @events = Event.where(category: 'atnd')
  end
  
  def facebook
    @facebook ||= settings.cache.fetch("facebook_#{Time.now.strftime('%Y-%m-%d')}") do
      facebook = []
      Facebook.all_of(object: 'link').each_with_index do |item, i|
        facebook[i/3] = [] if i % 3 == 0
        facebook[i/3][i%3] = item
      end
      settings.cache.set("facebook_#{Time.now.strftime('%Y-%m-%d')}", facebook, 60*60*24)
      facebook
    end
  end
end

get "/" do
  cache_control :public, max_age: 60*60*24
  
  events
  facebook
  
  sass :style
  haml :index 
end

post "/" do
  redirect "/"
end

get '/index.html' do
  haml :index
end

get '/more.html' do
  haml :more
end

get '/style.css' do
  sass :style
end

=begin
get '/daleteall' do
#  Event.destroy_all
#  Info.destroy_all
  redirect '/'
end
=end
