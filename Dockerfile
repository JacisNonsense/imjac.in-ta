FROM ruby:2.5
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs tree
RUN mkdir /imjacinta
WORKDIR /imjacinta

COPY . /imjacinta

RUN tree
RUN bundle install