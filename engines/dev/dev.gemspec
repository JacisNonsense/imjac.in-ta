$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "dev/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "dev"
  s.version     = Dev::VERSION
  s.authors     = ["Jaci Brunning"]
  s.email       = ["jaci.brunning@gmail.com"]
  s.homepage    = ""
  s.summary     = ""
  s.description = ""
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.1"
  s.add_dependency "rails-fontawesome5", "0.2.0"

  s.add_development_dependency "pg"
end
