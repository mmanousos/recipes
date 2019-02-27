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

When saving ingredients and directions to session from form, break them into separate elements in an array for each line break. Then render them back to user as separate lines.

Check for pre-existing recipe with identical name.

Register and Sign in
* Add Bcrypt gem
* Create credentials document
* Access credentials to compare username and password or write new info to it
* create compare credentials method
* create write new credentials method

Fix grid styling of recipe page
