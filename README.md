# Approvability

This is a quick and dirty approval system, allowing you to offer a submission and approval system that is agnostic to the model type it is approving. A quick example may be better than anything:

I've got the following models: Article and Product. Any registered user can submit articles and products. Any administrator can approve articles and products for public consumption. This gem does some of the heavy lifting.

## Install

1. Add the following to your Gemfile: 

	```
	gem 'approvability', :git => "//pretend/path/to/repo"
	```
	
2. Run the following rake task to generate some necessary files:

	```
	$ rake approvability:configure
	```
	
3. Edit the file it adds to +config/+ (make sure you restart your app at some point after this!)
	
4. Install the migrations:

	```
	$ rake approvability:install:migrations
	```
	
	Before running these migrations see "Additional Steps For Ease Of Use" step two, just in case.
	
5. And then add the following to each of the models that will be approvable:

	```
	acts_as_approvability
	```
	
## Great Big Gotchas
	
Currently the gem expects a number of forceful defaults, like the presence of two fields: `author_id` and `active` on each of the models that are approvable.

It expects you to have a `has_many` / `belongs_to` relationship between Author and any other model that `acts_as_approvability`.

## Todo

* Write good tests
* Integrate view generators and helpers
