require 'sinatra'
require 'erb'
require 'oauth2'
require 'byebug'
require 'dotenv'
require 'haml'
require 'sequel'
require 'time'
require "sinatra/reloader" if development?
require "httparty"
require 'json'
require 'sinatra/flash'

require_relative 'lib/nation_helper'

Dotenv.load
enable :sessions

configure do
  db = Sequel.connect('postgres://localhost/walklist')
  set :db, db
end

configure :production do
end

configure :test do
  db = Sequel.connect(ENV['SNAP_DB_PG_URL'] || "postgres://localhost/walklist_test")
  set :db, db
end

Sequel.datetime_class = DateTime

get '/' do
  if authorised?
    redirect '/electorates'
  else
    haml :main
  end
end

get '/login' do
  redirect '/'
end

post '/login' do
  nation_slug(params['nation']) #sets the nation slug
  oauth_client = OAuth2::Client.new(ENV['OAUTH_CLIENT_ID'], ENV['OAUTH_CLIENT_SECRET'], :site => site_path)
  redirect oauth_client.auth_code.authorize_url(:redirect_uri => ENV['REDIRECT_URI'])
end

get '/map' do
  haml :map
end

get '/authorise' do
  code = params['code']
  oauth_client = OAuth2::Client.new(ENV['OAUTH_CLIENT_ID'], ENV['OAUTH_CLIENT_SECRET'], :site => site_path)
  auth = oauth_client.auth_code.get_token(code, :redirect_uri => ENV['REDIRECT_URI'])
  nation_token(auth.token) #sets the auth token for this session.
  redirect '/electorates'
end

get '/electorates' do
  authorised do
    haml :electorates
  end
end
