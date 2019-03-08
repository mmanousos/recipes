# Recipe Application

## Purpose
Allow users to store and retrieve recipes.

## Functionality
* Add a recipe
  * Name
  * Ingredients
  * Directions
  * Image (optional)
  * Notes
* Delete a recipe
* Ability to edit name, ingredients, directions, or notes
* User must be registered and sign in to view or edit notes
* Display alphabetically (propercase names when uploading)

## Additional Functionality
* Edit button on recipes index page loads recipe page with all data in edit fields
* Import a recipe from an external site (scrape data using nokogiri?)
* Filter recipes by tags
* Display random recipe on welcome page each time a user visits
* Share button to allow users to send a recipe to a friend along with image and notes

## Design
Title for application
Header for homepage
Homepage lists all recipes as index - links to each recipe with delete and edit option

Recipe page: image at top of page
Table: Ingredients on left, Directions on right
Notes below

## Implementation
Will need erubis for erb files
Will use bcrypt for hashing passwords
Start with using an external location for images

Delete recipes  
* Create delete route
* Create delete method - access id from session hash & delete corresponding key-value
* Set session message: "'recipe name' deleted."
* Add delete button to view_recipe.erb

Add flash message div to layout.erb
Style flash messages

Check for pre-existing recipe with identical name.
Preserve entered data when notifying.

When saving ingredients and directions to session from form, break them into separate elements in an array for each line break. Then render them back to user as separate lines.

Create edit functionality
* make edit routes
* view existing content
* save to session

Option to add or change photo
* if no photo present, display 'add photo' button
* if photo exists, display 'replace' button

* Add 'delete' image option
* Resize image on display

Fix grid styling of recipe page

Register and Sign in
* Add Bcrypt gem
* Create credentials document
* Access credentials to compare username and password or write new info to it
* verify username for registration doesn't already exist
* create compare credentials method
* create write new credentials method

Write a method to display a flash message if trying to access a path that doesn't exist.
Write a method to prevent accessing `/recipe` path unless the user is signed in.
  Display a message 'You must be signed in to do that.'

Store recipes as individual entries in recipe document within file structure
  recipe document should be labeled for the user (new document for each user)
  * check if file exists: create or access it
    * name for user
  * store info within a YAML hash
    * Each recipe should get its own entry in the hash. Key is the Id. (as an integer not symbol)
    * title
    * ingredients
    * instructions
    * image - either link as string or filename to create path to image in directory
    * notes - empty string if blank
Store images as separate files within file structure
  if uploading an image - images should be in folder labeled for user
Files and images should have paired name/id so can be accessed simultaneously to display to user and deleted at the same time

Create new user - store username and hashed password in users.yml file.
there is no file for recipes yet.
create recipe file once first recipe is added.
  in add route, check if the file already exists.
    if no, create
    if yes, write to existing


Display welcome screen
  sign in or register
if signed in
  add a recipe or recipes
add recipe
  checks
    either loads or creates recipes document named for user

 * Need edit button for uploaded images
 * adjust edit route for content
  * simplify edit route
  * change edit route to not require capitalization

Working with deleting files
* `FileUtils.rm_rf` - removes entire directory even if it's not empty
* `FileUtils.rm_r` - removes entire directory even if it's not empty
* `FileUtils.rm_f` - force remove; doesn't do anything
`Errno::EPERM at /delete/1
Operation not permitted @ apply2files - public/images/newuser5/`
* `File.unlink`
* `FileUtils.remove_file`
* `File.delete`
- these errors were because I was not accessing the contents of the hash correctly (omitting the key prevented me from accessing the file name). After correcting that, `File.delete` worked perfectly!

* verify uploading file if 'upload' / link if 'link'

* show edit link for view_recipe page with uploaded images

Finalize image edit page
* add upload / link chooser on edit image view
* add 'upload' image link from edit image view
* rename & upload image (will automatically overwrite existing image?)
* if new link, add or overwrite existing
  * if upload: remove file and reference in 'upload' field
* if new upload, add or overwrite existing
  * if link, overwrite existing

## Remember to remove TODOS from recipes.rb and @recipes from top of recipes.erb
