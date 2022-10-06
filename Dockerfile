FROM ruby:2.7
RUN apt-get update && apt-get install -y nodejs
WORKDIR /app
COPY . .
RUN gem install bundler
RUN bundle install
CMD jekyll serve --host 0.0.0.0