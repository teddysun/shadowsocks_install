# Dockerfile for shadowsocks-libev based alpine
# Copyright (C) 2018 - 2019 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/shadowsocks/shadowsocks-libev
# https://github.com/shadowsocks/simple-obfs
# https://github.com/shadowsocks/v2ray-plugin

FROM golang:alpine AS builder
RUN set -ex \
	&& V2RAY_PLUGIN_VER="$(wget --no-check-certificate -qO- https://api.github.com/repos/shadowsocks/v2ray-plugin/releases/latest | grep 'tag_name' | cut -d\" -f4)" \
	&& apk add --no-cache git build-base \
	&& mkdir -p /go/src/github.com/shadowsocks \
	&& cd /go/src/github.com/shadowsocks \
	&& git clone https://github.com/shadowsocks/v2ray-plugin.git \
	&& cd v2ray-plugin \
	&& git checkout ${V2RAY_PLUGIN_VER} \
	&& go get -d \
	&& go build

FROM alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

RUN runDeps="\
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
	"; \
	set -ex \
	&& apk add --no-cache --virtual .build-deps ${runDeps} \
	&& mkdir -p /tmp/libev \
	&& cd /tmp/libev \
	&& git clone --depth=1 https://github.com/shadowsocks/simple-obfs.git . \
	&& git submodule update --init --recursive \
	&& ./autogen.sh \
	&& ./configure --prefix=/usr --disable-documentation \
	&& make install \
	&& rm -rf * \
	&& LIBEV_VER="$(wget --no-check-certificate -qO- https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest | grep 'tag_name' | cut -d\" -f4)" \
	&& LIBEV_NAME="shadowsocks-libev-$(echo ${LIBEV_VER} | sed -e 's/^[a-zA-Z]//g')" \
	&& LIBEV_RELEASE="https://github.com/shadowsocks/shadowsocks-libev/releases/download/${LIBEV_VER}/${LIBEV_NAME}.tar.gz" \
	&& wget -qO ${LIBEV_NAME}.tar.gz ${LIBEV_RELEASE} \
	&& tar zxf ${LIBEV_NAME}.tar.gz \
	&& cd ${LIBEV_NAME} \
	&& ./configure --prefix=/usr --disable-documentation \
	&& make install \
	&& apk add --no-cache rng-tools \
		$(scanelf --needed --nobanner /usr/bin/ss-* \
		| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
		| xargs -r apk info --installed \
		| sort -u) \
	&& apk del .build-deps \
	&& cd /tmp \
	&& rm -rf /tmp/libev

COPY --from=builder /go/src/github.com/shadowsocks/v2ray-plugin/v2ray-plugin /usr/bin
COPY ./config_sample.json /etc/shadowsocks-libev/config.json
VOLUME /etc/shadowsocks-libev

CMD [ "ss-server", "-c", "/etc/shadowsocks-libev/config.json" ]
