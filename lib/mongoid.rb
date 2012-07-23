require 'uri'
require 'mongoid'

Mongoid.configure do |config|
  if ENV['MONGOLAB_URI']
    uri  = URI.parse(ENV['MONGOLAB_URI'])
    conn = Mongo::Connection.from_uri(ENV['MONGOLAB_URI'])
    config.master = conn.db(uri.path.gsub(/^\//, ''))
  else
    env = Sinatra::Application.environment rescue nil
    name = env == :test ? 'test' : 'development'
    host = 'localhost'
    config.master = Mongo::Connection.new.db(name)
  end
end