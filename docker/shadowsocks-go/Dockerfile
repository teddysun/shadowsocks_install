# Dockerfile for Shadowsocks-go based alpine
# Copyright (C) 2018 - 2019 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/shadowsocks/shadowsocks-go

FROM golang:alpine AS builder
RUN set -ex \
	&& apk add --no-cache git \
	&& go get -u -v github.com/shadowsocks/shadowsocks-go/cmd/shadowsocks-server

FROM alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

COPY --from=builder /go/bin/shadowsocks-server /usr/bin
COPY config_sample.json /etc/shadowsocks-go/config.json
VOLUME /etc/shadowsocks-go

CMD [ "shadowsocks-server", "-c", "/etc/shadowsocks-go/config.json" ]
