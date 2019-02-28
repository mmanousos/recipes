require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

before do
  session[:recipes] ||= {}
  @recipes = session[:recipes]
end

helpers do
  def sort_recipes
    @recipes.sort_by { |_, recipe| recipe[:title]  }
  end
end

def next_id
  max_id = @recipes.keys.max
  max_id.nil? ? 1 : max_id + 1
end

def capitalize_title!(name)
  name.split.map(&:capitalize).join(' ')
end

def recipe_exists?(name)
  @recipes.any? { |_, recipe| recipe[:title] == name }
end

def recipe_errors?(name)
  session[:message] = 'A recipe with that name exists.' if recipe_exists?(name)
end

def split_lines(data)
  data_arr = data.strip.split("\r\n")
end

def add_recipe(title, ingredients, directions, image, notes)
  @recipes[next_id] = { title: title,
                        ingredients: ingredients,
                        directions: directions,
                        image: image,
                        notes: notes
                      }
end

def delete_recipe(id)
  @recipes.delete(id)
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
  erb :recipes
end

get '/recipe/:id' do
  @id = params[:id].to_i
  erb :view_recipe
end

post '/delete/:id' do
  id = params[:id].to_i
  session[:message] = "#{@recipes[id][:title]} recipe successfully deleted."
  delete_recipe(id)
  redirect '/recipes'
end

get '/add' do
  erb :add
end

get '/add/cancel' do
  redirect '/recipes'
end

post '/add' do
  # add recipe title, ingredients, directions, and notes as single file in file structure with image as additional file with same name
  # or add it to the session data structure
  @title = capitalize_title!(params[:title])
  @ingredients = split_lines(params[:ingredients])
  @directions = split_lines(params[:directions])
  @image = params[:image]
  @notes = params[:notes]

  error = recipe_errors?(@title)
  if error
    status 422
    erb :add
  else
    add_recipe(@title, @ingredients, @directions, @image, @notes)
    session[:message] = 'Recipe successfully added.'
    redirect '/recipes'
  end
end
