# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

namespace :docker do
  desc "Build docker image"
  task :build => [:depslayer] do
    system "docker-compose build --force-rm --parallel"
  end

  desc "Prepare dependencies layer"
  task :depslayer do
    require 'fileutils'
    FileUtils.mkdir_p 'build/depslayer'
    Dir.glob(['**/Gemfile', '**/*.gemspec']).each do |file|
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