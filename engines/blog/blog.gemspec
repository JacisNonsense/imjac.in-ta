$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "blog/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "blog"
  s.version     = Blog::VERSION
  s.authors     = ["Jaci Brunning"]
  s.email       = ["jaci.brunning@gmail.com"]
  s.homepage    = ""
  s.summary     = ""
  s.description = ""
  s.license     = "MIT"

  s.files = Dir["{config,lib,jekyll}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.1"
  s.add_dependency "jekyll", "3.5.2"
  s.add_dependency "jekyll-paginate", "1.1.0"
  s.add_dependency "kramdown", "1.15.0"
  s.add_dependency "rouge", "1.11.1"
  s.add_dependency "minima", "~> 2.0"

  s.add_development_dependency "pg"
end
