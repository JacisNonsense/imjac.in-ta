FROM jaci/rails-base:5.2.3-alpine

# Copy all dependency files over before the main stuff
# The reason for this is that it reduces the number of layers that
# require rebuilding. If we copied all the files here, the bundle install
# layer would require rebuilding every time, which is both time and space
# expensive.

# `rake docker:prepare_bundle` must be run before this
COPY ./build/depslayer /app

RUN bundle install

# Copy after we have installed dependencies
COPY . /app

# Rake inits everything, so we have to fake the keys
RUN rake assets:precompile blog:jekyll:build RAILS_ENV=production SECRET_KEY_BASE=`rake secret` RAILS_MASTER_KEY=`rake secret`

ENTRYPOINT ["sh", "/app/entrypoint.sh"]