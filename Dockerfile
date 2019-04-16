FROM ruby:2.6.0

RUN apt-get update -qq && apt-get install -y vim build-essential libpq-dev tree curl software-properties-common
RUN (curl -sL https://deb.nodesource.com/setup_11.x | bash -) && apt-get update -qq && apt-get install -y nodejs && npm install -g yarn

RUN mkdir /imjacinta
WORKDIR /imjacinta

# Copy all dependency files over before the main stuff
# The reason for this is that it reduces the number of layers that
# require rebuilding. If we copied all the files here, the bundle install
# layer would require rebuilding every time, which is both time and space
# expensive.

# `rake docker:prepare_bundle` must be run before this
COPY ./build/depslayer /imjacinta

RUN bundle install

# Copy after we have installed dependencies
COPY . /imjacinta

RUN bundle exec rake assets:precompile

ENTRYPOINT ["sh", "/imjacinta/entrypoint.sh"]