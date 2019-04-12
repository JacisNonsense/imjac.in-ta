module Blog
  class Engine < ::Rails::Engine
    require 'jekyll'
    require 'fileutils'

    isolate_namespace Blog

    if defined?(::Rails::Server)
      initializer "Jekyll" do |app|
        Rails.logger = Logger.new(STDOUT)

        jekylldir = Blog::Engine.root.join('jekyll').to_s
        config = Blog::Engine.root.join('config', 'jekyll.yml').to_s
        outroot = Blog::Engine.root.join('_site')

        FileUtils.rm_r outroot.to_s if File.exist? outroot.to_s

        Jekyll::Site.new(
          Jekyll.configuration({
            "config" => config,
            "source" => jekylldir,
            "destination" => outroot.join('ta').to_s
          })
        ).process

        Rails.logger.info("Jekyll site built!")

        app.middleware.use ::ActionDispatch::Static, outroot.to_s
      end
    end
  end
end
