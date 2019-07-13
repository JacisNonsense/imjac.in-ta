Gem::Specification.new do |s|
  s.name        = "blog"
  s.version     = "0.1.0"
  s.authors     = ["Jaci Brunning"]
  s.email       = ["jaci.brunning@gmail.com"]
  s.homepage    = ""
  s.summary     = ""
  s.description = ""
  s.license     = "MIT"

  s.files = Dir["{config,lib,jekyll}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "5.2.3"
  s.add_dependency "jekyll"
  s.add_dependency "jekyll-paginate"
  s.add_dependency "jekyll-paginate-multiple"
  s.add_dependency "kramdown"
  s.add_dependency "rouge"
  s.add_dependency "minima"
  s.add_dependency "jekyll-feed"
  s.add_dependency "premailer-rails"
  s.add_dependency "sidekiq-enqueuer"

  s.add_development_dependency "pg"
end
