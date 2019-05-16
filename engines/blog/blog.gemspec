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
  s.add_dependency "jekyll", "3.6.3"
  s.add_dependency "jekyll-paginate", "1.1.0"
  s.add_dependency "jekyll-paginate-multiple", "0.1.0"
  s.add_dependency "kramdown", "1.15.0"
  s.add_dependency "rouge", "1.11.1"
  s.add_dependency "minima", "~> 2.0"
  s.add_dependency "jekyll-feed", "0.11.0"
  s.add_dependency "premailer-rails", "1.10.2"
  s.add_dependency "sidekiq-enqueuer", "2.1.1"

  s.add_development_dependency "pg"
end
