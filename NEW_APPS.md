Creating new apps that run in the same environment
====

Small guide to creating apps that run in the same swarm / deployment as this website - for projects that deserve a standalone app, but may share the deployment resources.


# 1 - Generating
`rails new my-project`

# 2 - Setting up gems
- Move sqlite3 to the development dependencies
- Add `gem 'pg', '>= 0.18', '< 2.0'` as a dependency
- Add `gem "google-cloud-storage", require: false` as a dependency
- Add `gem 'prometheus-client'` as a dependency for metrics support

# 3 - Setting up dev (`config/environments/development.rb`)
- Add `config.action_mailer.delivery_method = :file` (if mailing support required)

Editing stuff in here doesn't really matter, since it's all local

# 4 - Setting up prod (`config/environments/production.rb`)
- `config.active_storage.service = :google`
- `config.force_ssl = true` (it's CURRENT_YEAR!!)

If using mailer (can change domain if required):
- `config.action_mailer.delivery_method = :smtp`
```ruby
config.action_mailer.smtp_settings = {
  address: 'mailer', 
  port: 587, 
  domain: 'imjac.in',
  openssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
}
```

# 5 - Database.yml
Replace the production section with:
```yml
production:
  <<: *default
  adapter: postgresql
  encoding: unicode
  host: db
  database: YOUR_PROJECT_DB
  username: <%= ENV['POSTGRES_USER'] %>
  password: <%= ENV['POSTGRES_PASSWORD'] %>
```

This keeps development using sqlite3. 

# 6 - Storage.yml
Don't forget to create the bucket in the GCP console
```yml
google:
   service: GCS
   project: imjacinta
   credentials: <%= ENV['GCS_CREDS'] %>
   bucket: YOUR_BUCKET
```

# 7 - Change master key
Change the master key to match the actual installation. You can keep this separate if you want, by changing the RAILS_MASTER_KEY env var.

If you haven't already got details in `credentials.yml.enc`, you can just delete the file and replace `master.key` with the one from this project.

- Copy the contents of `credentials.yml.enc` (open with `EDITOR=vi rails credentials:edit`)
- Replace `master.key` with the `master.key` from this project (DO NOT put it in git, or anywhere public!)
- Paste the old contents of `credentials.yml.enc`

# 8 - Docker setup
- Setup the entrypoint script (`entrypoint.sh`). Forwards the docker secrets as env vars.

```sh
#!/bin/bash

echo "Running Entrypoint Script"

if [ -f /run/secrets/secretkeybase ]; then
export "SECRET_KEY_BASE"=$(cat /run/secrets/secretkeybase)
fi

if [ -f /run/secrets/dbpass ]; then
export "POSTGRES_PASSWORD"=$(cat /run/secrets/dbpass)
fi

if [ -f /run/secrets/master ]; then
export "RAILS_MASTER_KEY"=$(cat /run/secrets/master)
fi

exec "$@"
```

- Setup .dockerignore (IMPORTANT!!!! Stops master key deploying)
```
**/tmp/
**/log/
**/node_modules/
**/storage/

config/master.key

ignored/

/*.yml
/*.toml
```

- Setup the Dockerfile
```Dockerfile
FROM ruby:2.6.0

RUN apt-get update -qq && apt-get install -y vim build-essential curl libpq-dev software-properties-common
RUN (curl -sL https://deb.nodesource.com/setup_11.x | bash -) && apt-get update -qq && apt-get install -y nodejs && npm install -g yarn

RUN gem install bundler

RUN mkdir /app
WORKDIR /app

RUN bundle install
COPY . /app

RUN rake assets:precompile RAILS_ENV=production SECRET_KEY_BASE=`rake secret` RAILS_MASTER_KEY=`rake secret`

ENTRYPOINT ["sh", "/app/entrypoint.sh"]
```

- Optional: Setup automated CI/CD with Azure pipelines. 

# 9 (optional) - Using Sidekiq
If you're using sidekiq, there are some extra steps...

- Insert sidekiq into your gemfile:
```ruby
gem 'sidekiq', '5.2.6'
gem 'sidekiq-scheduler', '~> 3.0.0' # Optional, if you need cron-like jobs
```

NOTE: If using sidekiq-scheduler, it's best to use an engine, since it needs to talk to the sidekiq server instance, which needs information from the project.

- Add `config/initializers/sidekiq.rb`. Don't forget to set `sidekiq_user` and `sidekiq_pass` in the rails credentials file.
```ruby
require 'sidekiq/web'

unless Rails.env.development?
  Sidekiq.configure_server do |cfg|
    cfg.redis = { url: 'redis://redis:6379/0', namespace: 'YOUR_APP' }  
  end

  Sidekiq.configure_client do |cfg|
    cfg.redis = { url: 'redis://redis:6379/0', namespace: 'YOUR_APP' }
  end

  Sidekiq::Web.use(Rack::Auth::Basic) do |user, pass|
    user == Rails.application.credentials.dig(:sidekiq_user)
    pass == Rails.application.credentials.dig(:sidekiq_pass)
  end
end
```

- Set sidekiq as the processor for ActiveJob
`config/application.rb`:

`config.active_job.queue_adapter = :sidekiq unless Rails.env.development?`

- Add sidekiq routes

`config/routes.rb`:

`require 'sidekiq/web'`
`mount Sidekiq::Web => "/sidekiq"`