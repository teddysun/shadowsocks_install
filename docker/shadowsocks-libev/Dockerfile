# Dockerfile for shadowsocks-libev
# Copyright (C) 2018 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/shadowsocks/shadowsocks-libev

FROM debian:stretch
LABEL maintainer="Teddysun <i@teddysun.com>"

RUN set -ex \
    && printf "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/stretch-backports.list \
    && apt-get update \
    && apt-get -t stretch-backports install -y --no-install-recommends shadowsocks-libev simple-obfs \
    && rm -rf /var/lib/apt/lists/*

COPY ./config_sample.json /etc/shadowsocks-libev/config.json
VOLUME /etc/shadowsocks-libev

USER nobody

CMD [ "ss-server", "-c", "/etc/shadowsocks-libev/config.json" ]
