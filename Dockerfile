FROM ruby:2.5
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs tree
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