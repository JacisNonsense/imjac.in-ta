module Blog
  class Engine < ::Rails::Engine
    require 'jekyll'
    require 'fileutils'
    require 'premailer/rails'

    isolate_namespace Blog

    initializer "blog.precompile" do |app|
      app.config.assets.precompile << %w( blog/email-milligram.css )
    end

    if defined?(::Rails::Server)
      initializer "Jekyll" do |app|
        app.middleware.use ::ActionDispatch::Static, File.expand_path("~/.blog")
      end

      initializer "Premailer" do |app|
        Premailer::Rails.config.merge!(preseve_styles: true, remove_ids: true)
      end

      initializer "Blog Post DB Update" do |app|
        # Wait a few minutes before updating the articles.
        UpdateArticlesListJob.set(wait: 2.minute).perform_later
      end
    end
  end
end
