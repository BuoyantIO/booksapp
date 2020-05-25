FROM ruby:2.7.1-alpine3.11

RUN apk add --update \
    alpine-sdk \
    jq \
    mariadb-dev \
    netcat-openbsd \
    sqlite-dev \
  && rm -rf /var/cache/apk/*

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY Gemfile* /usr/src/app/
RUN bundle install

COPY . /usr/src/app
ENTRYPOINT ["bundle", "exec", "rake"]
