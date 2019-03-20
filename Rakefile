# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

def get_docker_tag
  # "#{`git rev-parse --short HEAD`.strip}#{`git diff --quiet || echo -dirty`.strip}"
  File.read("VERSION")
end

def get_docker_img
  "jaci/imjacinta:#{get_docker_tag}"
end

namespace :docker do
  desc "Build docker image"
  task :build => [:depslayer] do
    system "docker build -t #{get_docker_img} ."
  end

  task :push => [:build] do
    system "docker push #{get_docker_img}"
  end

  task :get_tag do
    puts get_docker_tag
  end

  task :get_image do
    puts get_docker_img
  end

  desc "Build docker and launch"
  task :up => [:depslayer] do
    system "docker-compose up --build"
  end

  desc "Prepare dependencies layer"
  task :depslayer do
    require 'fileutils'
    FileUtils.mkdir_p 'build/depslayer'
    Dir.glob(['**/Gemfile', '**/Gemfile.lock', '**/*.gemspec']).each do |file|
      next if file.include?('build/depslayer')
      
      dest = "build/depslayer/#{file}"
      FileUtils.mkdir_p(File.dirname(dest))
      
      if !File.exist?(dest) || File.read(file) != File.read(dest)
        puts "Update: #{file} -> #{dest}"
        FileUtils.cp(file, dest) 
      end
    end
  end
end