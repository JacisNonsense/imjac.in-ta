module Blog
  class Engine < ::Rails::Engine
    require 'jekyll'
    require 'fileutils'

    isolate_namespace Blog

    initializer "jekyll site" do |app|
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

      puts "Built Jekyll Site!"

      app.middleware.use ::ActionDispatch::Static, outroot.to_s
    end
  end
end
