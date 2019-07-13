Gem::Specification.new do |s|
  s.name        = "dev"
  s.version     = "0.1.0"
  s.authors     = ["Jaci Brunning"]
  s.email       = ["jaci.brunning@gmail.com"]
  s.homepage    = ""
  s.summary     = ""
  s.description = ""
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "5.2.3"
  s.add_dependency "jquery-rails"
  s.add_dependency "rails-ujs"
  s.add_dependency "rails-fontawesome5"
  s.add_dependency "devise"

  s.add_dependency "rubyzip"

  s.add_development_dependency "pg"
end
