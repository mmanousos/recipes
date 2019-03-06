require 'bcrypt'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'yaml'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

def file_path(file)
  File.absolute_path(file)
end

def load_credentials
  path = file_path('users.yml')
  YAML.load_file(path)
end

before do
  session[:signedin] ||= false
  @credentials = load_credentials
  @recipes = if session[:username].nil?
                nil
             else
                load_recipes(session[:username])
             end
end

helpers do
  def sort_recipes
    @recipes.sort_by { |_, recipe| recipe[:title]  }
  end

  def no_image?(id)
    @recipes[id][:image].empty? && @recipes[id][:upload].nil?
  end

  def signed_in?
    session[:signedin] == true
  end

  def get_image_path(name)
    if name =~ /http/
      name
    else
      File.join('/images', "#{session[:username].to_s}", name)
    end
  end
end

def create_user(username, password)
  @credentials[username] = BCrypt::Password.create(password)
  File.open(file_path('users.yml'), 'w') do |f|
    f.write(@credentials.to_yaml)
  end
end

def invalid_credentials?(username, password)
  !@credentials.keys.include?(username) ||
  BCrypt::Password.new(@credentials[username]) != password
end

def invalid_username?(username)
  @credentials.keys.include?(username)
end

def check_credentials
  if !signed_in?
    session[:message] = "You must be signed in to do that."
    redirect '/'
  end
end

def load_recipes(username)
  YAML.load_file(file_path("data/#{username}.yml"))
end

def max_recipe_id
  @recipes.keys.max
end

def next_id
  max_id = max_recipe_id
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

def rename_image(name)
  extension = File.extname(name)
  next_id.to_s + extension
end

def add_recipe(title, ingredients, instructions, image, upload, notes)
  @recipes[next_id] = { title: title,
                        ingredients: ingredients,
                        instructions: instructions,
                        image: image,
                        upload: upload,
                        notes: notes
                      }
  File.open("data/#{session[:username]}.yml", 'w') do |f|
    f.write(@recipes.to_yaml)
  end
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

not_found do
  session[:message] = 'Requested page not found. Please try again.'
  if signed_in?
    redirect '/recipes'
  else
    redirect '/'
  end
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
  username = params[:username].to_sym
  password = params[:password]
  if invalid_credentials?(username, password)
    status 422
    session[:message] = 'Invalid credentials. Please try again or register.'
    erb :signin
  else
    session[:username] = username
    session[:signedin] = true
    session[:message] = "Welcome, #{username}!"
    redirect '/recipes'
  end
end

post '/register' do
  username = params[:username].to_sym
  password = params[:password]
  if invalid_username?(username)
    session[:message] = 'Username already exists. Choose another or sign in.'
    status 422
    erb :register
  else
    create_user(username, password)
    session[:username] = username
    session[:signedin] = true
    session[:message] = "New user successfully registered. Welcome, #{username}!"
    redirect '/recipes'
  end
end

post '/signout' do
  session.delete(:username)
  session[:signedin] = false
  session[:message] = 'Sign Out successful. See you again soon.'
  redirect '/'
end

get '/recipes' do
  check_credentials
  load_recipes(session[:username])
  erb :recipes
end

get '/recipe/:id' do
  check_credentials
  id = params[:id].to_i
  if max_recipe_id.nil? || id > max_recipe_id
    session[:message] = "We couldn't find your requested recipe."
    redirect '/recipes'
  else
    @id = id
    erb :view_recipe
  end
end

post '/delete/:id' do
  check_credentials
  id = params[:id].to_i
  session[:message] = "#{@recipes[id][:title]} recipe successfully deleted."
  delete_recipe(id)
  redirect '/recipes'
end

get '/add' do
  check_credentials
  erb :add
end

get '/edit/:id/title' do
  check_credentials
  @id = params[:id].to_i
  @subject = 'Title'
  erb :edit
end

get '/edit/:id/ingredients' do
  check_credentials
  @id = params[:id].to_i
  @subject = 'Ingredients'
  erb :edit
end

get '/edit/:id/instructions' do
  check_credentials
  @id = params[:id].to_i
  @subject = 'Instructions'
  erb :edit
end

get '/edit/:id/notes' do
  check_credentials
  @id = params[:id].to_i
  @subject = 'Notes'
  erb :edit
end

post '/edit/:id/Title' do
  check_credentials
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
  check_credentials
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
  check_credentials
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
  check_credentials
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
  check_credentials
  @id = params[:id].to_i
  erb :image
end

post '/image/:id' do
  check_credentials
  id = params[:id].to_i
  @recipes[id][:image] = params[:image]
  redirect "/recipe/#{id}"
end

post '/image/:id/delete' do
  check_credentials
  id = params[:id].to_i
  @recipes[id][:image] = ''
  redirect "/recipe/#{id}"
end

get '/add/cancel' do
  check_credentials
  redirect '/recipes'
end

def check_image(choice, url)
  case choice
  when 'link'           then url
  when 'none', 'upload' then ''
  end
end

def save_upload(image)
  # check if folder exists
  path = "public/images/#{session[:username]}"
  name = rename_image(image[:filename].to_s)
  FileUtils.mv(image[:tempfile], File.join(path, name))
end

post '/add' do
  check_credentials
  @title = capitalize_title!(params[:title])
  @ingredients = split_lines(params[:ingredients])
  @instructions = split_lines(params[:instructions])
  choice = params[:image_pick]
  image = params[:image]
  upload = rename_image(params[:upload_image][:filename]) if choice == 'upload'
  @image = check_image(choice, image)
  @notes = params[:notes]

  error = recipe_errors?(@title)
  if error
    status 422
    erb :add
  else
    save_upload(params[:upload_image]) if choice == 'upload'
    add_recipe(@title, @ingredients, @instructions, @image, upload, @notes)
    session[:message] = 'Recipe successfully added.'
    redirect '/recipes'
  end
end

# check if username image file exists
# create if it doesn't
# move image to username file
