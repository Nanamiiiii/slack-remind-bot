FROM ruby:3.0.2
ENV LANG C.UTF-8

RUN apt update -qq && apt install -y build-essential mariadb-client

WORKDIR /remind-bot-api
COPY Gemfile /remind-bot-api/Gemfile
COPY Gemfile.lock /remind-bot-api/Gemfile.lock
ENV BUNDLER_VERSION 2.2.16
RUN gem update --system && gem install bundler -v $BUNDLER_VERSION
RUN bundle install
COPY . /remind-bot-api

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
