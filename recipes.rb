require 'bcrypt'
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

  def no_image?(id)
    @recipes[id][:image].empty?
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

def add_recipe(title, ingredients, instructions, image, notes)
  @recipes[next_id] = { title: title,
                        ingredients: ingredients,
                        instructions: instructions,
                        image: image,
                        notes: notes
                      }
end

def delete_recipe(id)
  @recipes.delete(id)
end

def empty_field?(content)
  if content.class == String
    content.empty? || content.strip.empty?
  elsif content.class == Array
    content.empty? || content.all? { |el| el.strip.empty? }
  end
end

def update_content(id, content, key)
  @recipes[id][key] = content
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

get '/edit/:id/title' do
  @id = params[:id].to_i
  @subject = 'Title'
  erb :edit
end

get '/edit/:id/ingredients' do
  @id = params[:id].to_i
  @subject = 'Ingredients'
  erb :edit
end

get '/edit/:id/instructions' do
  @id = params[:id].to_i
  @subject = 'Instructions'
  erb :edit
end

get '/edit/:id/notes' do
  @id = params[:id].to_i
  @subject = 'Notes'
  erb :edit
end

post '/edit/:id/Title' do
  @id = params[:id].to_i
  @title = capitalize_title!(params[:title])
  error = recipe_errors?(@title)
  if error
    @subject = 'Title'
    status 422
    erb :edit
  else
    update_content(@id, @title, :title)
    redirect "/recipe/#{@id}"
  end
end

post '/edit/:id/Ingredients' do
  @id = params[:id].to_i
  @ingredients = split_lines(params[:ingredients])
  if empty_field?(@ingredients)
    session[:message] = 'Field can not be empty.'
    @subject = 'Ingredients'
    status 422
    erb :edit
  else
    update_content(@id, @ingredients, :ingredients)
    redirect "/recipe/#{@id}"
  end
end

post '/edit/:id/Instructions' do
  @id = params[:id].to_i
  @instructions = split_lines(params[:instructions])
  if empty_field?(@instructions)
    session[:message] = 'Field can not be empty.'
    @subject = 'Instructions'
    status 422
    erb :edit
  else
    update_content(@id, @instructions, :instructions)
    redirect "/recipe/#{@id}"
  end
end

post '/edit/:id/Notes' do
  @id = params[:id].to_i
  @notes = params[:notes]
  if empty_field?(@notes)
    session[:message] = 'Field can not be empty.'
    @subject = 'Notes'
    status 422
    erb :edit
  else
    update_content(@id, @notes, :notes)
    redirect "/recipe/#{@id}"
  end
end

get '/image/:id' do
  @id = params[:id].to_i
  erb :image
end

post '/image/:id' do
  id = params[:id].to_i
  @recipes[id][:image] = params[:image]
  redirect "/recipe/#{id}"
end

post '/image/:id/delete' do
  id = params[:id].to_i
  @recipes[id][:image] = ''
  redirect "/recipe/#{id}"
end

get '/add/cancel' do
  redirect '/recipes'
end

post '/add' do
  @title = capitalize_title!(params[:title])
  @ingredients = split_lines(params[:ingredients])
  @instructions = split_lines(params[:instructions])
  @image = params[:image]
  @notes = params[:notes]

  error = recipe_errors?(@title)
  if error
    status 422
    erb :add
  else
    add_recipe(@title, @ingredients, @instructions, @image, @notes)
    session[:message] = 'Recipe successfully added.'
    redirect '/recipes'
  end
end
