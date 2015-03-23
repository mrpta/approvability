module Approvability
  class Engine < ::Rails::Engine
    isolate_namespace Approvability
    
    def self.configuration
      if self.configuration_exists?
        @configuration ||= YAML::load(ERB.new(IO.read(self.path_to_configuration)).result)
      else
        puts "### APPROVABILITY WARNING: Using default configuration, create config/approvability.yml to override."
        @configuration ||= YAML::load(ERB.new(IO.read(self.path_to_default_configuration)).result)        
      end
    end
    
    def self.configuration_exists?
      File.exists? self.path_to_configuration
    end
    
    def self.path_to_configuration
      Rails.root.join("config/approvability.yml")
    end
    
    def self.path_to_default_configuration
      File.expand_path("../../../config/approvability.yml", __FILE__)
    end
  end
end
