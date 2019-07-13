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
  spec.add_dependency "bootstrap"
  spec.add_dependency "rails-fontawesome5"
  spec.add_dependency "jquery-rails"
  spec.add_dependency "react-rails"
  spec.add_dependency "sidekiq-scheduler"

  spec.add_development_dependency "pg"
end
 