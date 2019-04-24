# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'
require_relative 'docker'

Rails.application.load_tasks

namespace :docker do
  desc "Build docker image"
  task :build do
    docker_build
  end

  task :push do
    docker_push
  end

  desc "Build docker and launch"
  task :up do
    docker_up_dev
  end

  task :deploy do
    docker_deploy
  end

end
