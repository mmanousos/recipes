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
  @recipes = verify_file
end

def verify_file
  if session[:username].nil?
    nil
  elsif verify_recipes?
    load_recipes(session[:username])
  end
end

helpers do
  def verify_recipes?
    File.exists?("data/#{session[:username]}.yml")
  end

  def sort_recipes
    @recipes.sort_by { |_, recipe| recipe[:title]  }
  end

  def link_empty?(id)
    @recipes[id][:image].empty?
  end

  def no_image?(id)
    link_empty?(id) && @recipes[id][:upload].nil?
  end

  def signed_in?
    session[:signedin] == true
  end

  def image_path(name)
    File.join('/images', "#{session[:username].to_s}", name)
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
  if @recipes && !@recipes.empty?
    @recipes.keys.max
  else
    0
  end
end

def next_id
  max_id = max_recipe_id
  max_id.nil? ? 1 : max_id + 1
end

def capitalize_title!(name)
  name.split.map(&:capitalize).join(' ')
end

def recipe_exists?(name)
  if verify_recipes? && @recipes.class == Hash
    @recipes.any? { |_, recipe| recipe[:title] == name }
  end
end

def name_error?(name)
  session[:message] = 'A recipe with that name exists.' if recipe_exists?(name)
end

def image_errors?(choice, image, upload)
  if choice == 'link' && image.empty?
    session[:message] = 'Please provide a link to your recipe image or ' \
                        'select "upload" to upload a file from your computer.'
  elsif choice == 'upload' && upload.nil?
    session[:message] = 'Please upload an image of your recipe or select ' \
                        '"link" to provide a url to an existing image.'
  elsif choice == 'none' && !image.empty?
    session[:message] = 'If you would like to use a url of an existing image,' \
                        ' please select "link" and try again.'
  elsif choice == 'none' && upload
    session[:message] = 'If you would like to upload your own image, please' \
                        ' select "upload" and try again.'
  end
end

def check_image(choice, url)
  case choice
  when 'link'           then url
  when 'none', 'upload' then ''
  end
end

def check_upload(choice)
  rename_image(params[:upload_image][:filename]) if choice == 'upload'
end

def create_folder
  Dir.mkdir("public/images/#{session[:username]}")
end

def directory_exists?
  Dir.exist?("public/images/#{session[:username]}")
end

def save_upload(image)
  create_folder unless directory_exists?
  path = "public/images/#{session[:username]}"
  name = rename_image(image[:filename].to_s)
  FileUtils.mv(image[:tempfile], File.join(path, name))
end

def split_lines(data)
  data_arr = data.strip.split("\r\n")
end

def rename_image(name)
  extension = File.extname(name)
  next_id.to_s + extension
end

def create_user_recipes(username)
  File.new("data/#{username}.yml", 'w+')
end

def pull_recipes
  username = session[:username]
  if verify_recipes?
    load_recipes(username)
  else
   create_user_recipes(username)
   load_recipes(username)
  end
end

def write_to_recipes(recipes, username)
  File.open("data/#{username}.yml", 'w') do |f|
    f.write(recipes.to_yaml)
  end
end

def add_recipe(title, ingredients, instructions, image, upload, notes)
  @recipes = pull_recipes
  @recipes ||= {}
  @recipes[next_id] = { title: title,
                        ingredients: ingredients,
                        instructions: instructions,
                        image: image,
                        upload: upload,
                        notes: notes
                      }
  write_to_recipes(@recipes, session[:username])
end

def delete_recipe(id)
  username = session[:username]
  @recipes = load_recipes(username)
  image = @recipes[id][:upload]
  delete_image(image, username) if image
  @recipes.delete(id)
  write_to_recipes(@recipes, username)
end

def delete_image(image, username)
  File.delete("public/images/#{username}/#{image}")
end

def empty_field?(content)
  if content.class == String
    content.empty? || content.strip.empty?
  elsif content.class == Array
    content.empty? || content.all? { |el| el.strip.empty? }
  end
end

def content_error?(content)
  session[:message] = 'Field can not be empty.' if empty_field?(content)
end

# update content of singular recipe field
def update_content(id, content, key)
  @recipes[id][key] = content
  write_to_recipes(@recipes, session[:username])
end

not_found do
  session[:message] = 'Requested page not found. Please try again.'
  signed_in? ? (redirect '/recipes') : (redirect '/')
end

# display welcome view
get '/' do
  erb :welcome
end

# display sign in view
get '/signin' do
  erb :signin
end

# display register view
get '/register' do
  erb :register
end

# return to welcome page from sign in view
get '/signin/cancel' do
  redirect '/'
end

# return to welcome page from register view
get '/register/cancel' do
  redirect '/'
end

# sign in existing user
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

# register new user
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

# sign out
post '/signout' do
  session.delete(:username)
  session[:signedin] = false
  session[:message] = 'Sign Out successful. See you again soon.'
  redirect '/'
end

# load recipes index
get '/recipes' do
  check_credentials
  load_recipes(session[:username]) if verify_recipes?
  erb :recipes
end

# load individual recipe
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

# delete individual recipe
post '/delete/:id' do
  check_credentials
  id = params[:id].to_i
  session[:message] = "#{@recipes[id][:title]} recipe successfully deleted."
  delete_recipe(id)
  redirect '/recipes'
end

# load edit contents view
get '/edit/:id/:subject' do
  check_credentials
  @id = params[:id].to_i
  @subject = params[:subject]
  erb :edit
end

# edit content
post '/edit/:id/:subject' do
  check_credentials
  @id = params[:id].to_i
  @subject = params[:subject]
  @content = params[@subject.to_sym]
  case @subject
  when 'title'
    @content = capitalize_title!(@content)
    error = name_error?(@content)
  when 'ingredients'
    @content = split_lines(@content)
    error = content_error?(@content)
  when 'instructions'
    @content = split_lines(@content)
    error = content_error?(@content)
  when 'notes'
    error = content_error?(@content)
  end
  if error
    status 422
    erb :edit
  else
    update_content(@id, @content, @subject.to_sym)
    redirect "/recipe/#{@id}"
  end
end

# load image edit view
get '/image/:id' do
  check_credentials
  @id = params[:id].to_i
  erb :image
end

# TODO: update this to adjust image in file and/or hash
# update image
post '/image/:id' do
  check_credentials
  id = params[:id].to_i
  @recipes[id][:image] = params[:image]
  redirect "/recipe/#{id}"
end

# delete image from recipe or edit views
post '/image/:id/delete' do
  check_credentials
  id = params[:id].to_i
  if !link_empty?(id)
    update_content(id, '', :image)
  elsif !@recipes[id][:upload].nil? # remove value from :upload and
    image = @recipes[id][:upload]
    update_content(id, nil, :upload)
    delete_image(image, session[:username])
  end
  redirect "/recipe/#{id}"
end

# load add recipe view
get '/add' do
  check_credentials
  erb :add
end

# cancel add recipe view - return to recipes index
get '/add/cancel' do
  check_credentials
  redirect '/recipes'
end

# add new recipe
post '/add' do
  check_credentials
  @title = capitalize_title!(params[:title])
  @ingredients = split_lines(params[:ingredients])
  @instructions = split_lines(params[:instructions])
  choice = params[:image_pick]
  @image = params[:image]
  upload = params[:upload_image] || nil
  @notes = params[:notes]

  name_error = name_error?(@title)
  image_error = image_errors?(choice, @image, upload)
  if name_error || image_error
    status 422
    erb :add
  else
    @image = check_image(choice, @image)
    upload = check_upload(choice)
    save_upload(params[:upload_image]) if choice == 'upload'
    add_recipe(@title, @ingredients, @instructions, @image, upload, @notes)
    session[:message] = 'Recipe successfully added.'
    redirect '/recipes'
  end
end
