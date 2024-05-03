FROM ruby:2.7
# FROM ruby:3.0
RUN apt-get update && apt-get install -y nodejs
WORKDIR /app
COPY Gemfile .
COPY Gemfile.lock .
RUN gem install bundler -v 2.4.22
# RUN gem install bundler
RUN bundle install

COPY . .

EXPOSE 4000
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0"]
