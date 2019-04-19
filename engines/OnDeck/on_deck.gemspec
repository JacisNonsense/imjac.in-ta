Gem::Specification.new do |spec|
  spec.name        = "on_deck"
  spec.version     = "0.1.0"
  spec.authors     = ["Jaci Brunning"]
  spec.email       = ["jaci.brunning@gmail.com"]
  spec.homepage    = ""
  spec.summary     = ""
  spec.description = ""
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "5.2.3"
  spec.add_dependency "bootstrap", "~> 4.3.1"
  spec.add_dependency "rails-fontawesome5", "0.2.0"
  spec.add_dependency "jquery-rails", "~> 4.3.3"

  spec.add_development_dependency "pg"
end
 