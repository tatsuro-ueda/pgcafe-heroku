require 'rubygems'
require 'bundler'

require 'date'
require 'open-uri'

Bundler.require

set :root, File.dirname(__FILE__)

require './app'
run Sinatra::Application