$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "approvability/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "approvability"
  s.version     = Approvability::VERSION
  s.authors     = ["Paul Atkinson"]
  s.email       = ["info@paulatkinson.co.nz"]
  s.homepage    = "http://www.paulatkinson.co.nz/approvability"
  s.summary     = "Enables models to act_as_approvability, allowing contributors to submit content and an administrator to approve it"
  s.description = "Adds the extensions to any approvable model to check and create approvable objects as required, email the administrators to keep up to date, provide an action-item feed, views and stats for contributors, and more."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.13"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "sqlite3"
end
