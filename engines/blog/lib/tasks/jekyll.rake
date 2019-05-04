def build_jekyll
  engroot = File.join(File.dirname(__FILE__), "../../").to_s
  jekylldir = File.join(engroot, "jekyll").to_s
  config = File.join(engroot, "config/jekyll.yml").to_s
  outroot = "~/.blog"
  
  FileUtils.rm_r outroot if File.exist? outroot

  Jekyll::Site.new(
    Jekyll.configuration({
      "config" => config,
      "source" => jekylldir,
      "destination" => File.join(outroot, 'ta').to_s
    })
  ).process
end

namespace :blog do 
  namespace :jekyll do
    desc "Build jekyll site"
    task build: :environment do 
      build_jekyll
    end

    desc ""
    task build_watch: :environment do
      loop do
        build_jekyll
        sleep 1
      end
    end
  end
end