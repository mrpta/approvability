# desc "Explaining what the task does"
# task :approvability do
#   # Task goes here
# end

namespace :approvability do
   desc "Creates the approvaibility.yml configure file"
   task :configure do
      puts "Creating config/approvability.yml"
      FileUtils.cp(Approvability::Engine.path_to_default_configuration, Rails.root.join("config/"))
   end
end