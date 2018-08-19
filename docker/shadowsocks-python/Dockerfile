# Dockerfile for Shadowsocks-Python based alpine
# Copyright (C) 2018 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/shadowsocks/shadowsocks/tree/master

FROM python:3.6-alpine
LABEL maintainer="Teddysun <i@teddysun.com>"

RUN runDeps="\
		unzip \
		wget \
		libsodium-dev \
		openssl \
		mbedtls \
	"; \
	set -ex \
	&& apk add --no-cache --virtual .build-deps ${runDeps} \
	&& cd /tmp \
	&& wget -O shadowsocks.zip https://github.com/shadowsocks/shadowsocks/archive/master.zip \
	&& unzip shadowsocks.zip \
	&& cd shadowsocks-master \
	&& python setup.py install \
	&& cd /tmp \
	&& rm -fr shadowsocks.zip shadowsocks-master 

COPY config_sample.json /etc/shadowsocks-python/config.json
VOLUME /etc/shadowsocks-python

USER nobody

CMD [ "ssserver", "-c", "/etc/shadowsocks-python/config.json" ]