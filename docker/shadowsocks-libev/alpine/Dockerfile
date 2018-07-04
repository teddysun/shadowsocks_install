# Dockerfile for shadowsocks-libev based alpine
# Copyright (C) 2018 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/shadowsocks/shadowsocks-libev

FROM alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

ENV LIBEV_VER 3.2.0
ENV LIBEV_NAME shadowsocks-libev-${LIBEV_VER}
ENV LIBEV_RELEASE https://github.com/shadowsocks/shadowsocks-libev/releases/download/v${LIBEV_VER}/${LIBEV_NAME}.tar.gz

RUN set -ex \
    && runDeps=' \
       tar \
       git \
       wget \
       build-base \
       c-ares-dev \
       autoconf \
       automake \
       libev-dev \
       libtool \
       libsodium-dev \
       linux-headers \
       mbedtls-dev \
       pcre-dev \
       ' \
    && apk add --no-cache --virtual .build-deps \
       ${runDeps} \
    && mkdir -p /tmp/libev \
    && cd /tmp/libev \
    && git clone --depth=1 https://github.com/shadowsocks/simple-obfs.git . \
    && git submodule update --init --recursive \
    && ./autogen.sh \
    && ./configure --prefix=/usr --disable-documentation \
    && make install \
    && rm -rf * \
    && wget -qO ${LIBEV_NAME}.tar.gz ${LIBEV_RELEASE} \
    && tar zxf ${LIBEV_NAME}.tar.gz \
    && cd ${LIBEV_NAME} \
    && ./configure --prefix=/usr --disable-documentation \
    && make install \
    && apk add --no-cache \
       rng-tools \
       $(scanelf --needed --nobanner /usr/bin/ss-* \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | xargs -r apk info --installed \
      | sort -u) \
    && apk del .build-deps \
    && cd /tmp \
    && rm -rf /tmp/libev \

COPY ./config_sample.json /etc/shadowsocks-libev/config.json
VOLUME /etc/shadowsocks-libev

USER nobody

CMD [ "ss-server", "-c", "/etc/shadowsocks-libev/config.json" ]