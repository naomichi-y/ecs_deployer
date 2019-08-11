FROM ruby:2.6.3-alpine3.10

RUN apk add git build-base
RUN git config --global user.name "Naomichi Yamakita"
WORKDIR /app

COPY . .
RUN bundle install
