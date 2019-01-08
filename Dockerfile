FROM alpine:latest

RUN apk update

# build dependencies
RUN apk add --no-cache ruby ruby-dev
RUN apk add --no-cache git
RUN apk add --no-cache make gcc libc-dev
RUN git clone https://github.com/securityscorecard/dogscaler.git /tmp/dogscaler
WORKDIR /tmp/dogscaler

# build
RUN gem install --no-document bigdecimal
RUN gem build dogscaler.gemspec
RUN gem install --no-document dogscaler*gem

# clean up after build
RUN rm -rf /tmp/dogscaler
RUN apk del ruby-dev
RUN apk del git
RUN apk del make gcc libc-dev


WORKDIR /

ENTRYPOINT ["dogscaler"]
