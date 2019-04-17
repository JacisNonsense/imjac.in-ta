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

def exec_machine command
  name = ENV['name'] || 'imjacinta'
  status = `docker-machine status #{name}`
  raise "Machine does not exist! Use rake docker:create_deployment to make one!" if status.include?("does not exist")

  exec "/bin/sh -c \"eval \\\"$(docker-machine env #{name})\\\" && #{command}\""
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

  task :create_deployment do
    key = ENV['key'] || '~/.ssh/id_rsa'
    name = ENV['name'] || 'imjacinta'
    user = ENV['sshuser'] || 'root'
    host = ENV['ip']

    raise "No IP given! Provide it with 'ip=XX.XX.XX.XX'" if host.nil? || host.empty?

    if `docker-machine status #{name}`.include?("does not exist")
      puts "Creating Docker-Machine with IP: #{host}, Name: #{name}, SSH Key: #{key}, SSH User: #{user}"
      exec "docker-machine create --driver generic --generic-ip-address #{host} --generic-ssh-user #{user} --generic-ssh-key #{key} #{name}"
    else
      puts "Machine already exists!"
    end
  end

  task :deploy do
    exec_machine "docker stack deploy --compose-file=docker-compose-prod.yml imjacinta"
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