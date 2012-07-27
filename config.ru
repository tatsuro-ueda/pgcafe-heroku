require 'rubygems'
require 'bundler'

Bundler.require

set :root, File.dirname(__FILE__)

require './app'
run Sinatra::Application