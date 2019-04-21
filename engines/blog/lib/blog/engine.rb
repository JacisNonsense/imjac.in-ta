module Blog
  class Engine < ::Rails::Engine
    require 'jekyll'
    require 'fileutils'

    isolate_namespace Blog

    if defined?(::Rails::Server)
      initializer "Jekyll" do |app|
        app.middleware.use ::ActionDispatch::Static, File.expand_path("~/.blog")
      end
    end
  end
end
