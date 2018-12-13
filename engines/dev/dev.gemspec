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

  s.add_dependency "rails", "~> 5.2.1"
  s.add_dependency "rails-fontawesome5", "0.2.0"

  s.add_development_dependency "pg"
end
