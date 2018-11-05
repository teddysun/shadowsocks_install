# Dockerfile for Shadowsocks-go based alpine
# Copyright (C) 2018 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/shadowsocks/shadowsocks-go

FROM alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

RUN runDeps="\
	wget \
	"; \
	set -ex \
	&& apk add --no-cache --virtual .build-deps ${runDeps} \
	&& mkdir /lib64 \
	&& ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 \
	&& cd /tmp \
	&& wget -qO shadowsocks-server-linux64-1.2.2.gz https://dl.lamp.sh/shadowsocks/shadowsocks-server-linux64-1.2.2.gz \
	&& gzip -d shadowsocks-server-linux64-1.2.2.gz \
	&& chmod 755 shadowsocks-server-linux64-1.2.2 \
	&& mv shadowsocks-server-linux64-1.2.2 /usr/bin/shadowsocks-server \
	&& apk del .build-deps

COPY config_sample.json /etc/shadowsocks-go/config.json
VOLUME /etc/shadowsocks-go

USER nobody

CMD [ "shadowsocks-server", "-c", "/etc/shadowsocks-go/config.json" ]