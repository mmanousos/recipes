require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

get '/' do
  erb :welcome
end

get '/signin' do
  erb :signin
end

get '/register' do
  erb :register
end

get '/signin/cancel' do
  redirect '/'
end

get '/register/cancel' do
  redirect '/'
end

post '/signin' do
  # redirect to recipes index
end

post '/register' do
  # redirect to recipes index
end

get '/recipes' do
  
end

get '/add' do
  erb :add
end

get '/add/cancel' do
  redirect '/recipes' # redirect to list of recipes
end

post '/add/' do
  # add recipe title, ingredients, directions, and notes as single file in file structure with image as additional file with same name
  # or add it to the session data structure
end
