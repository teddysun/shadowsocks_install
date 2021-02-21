# Dockerfile for go-shadowsocks2 based alpine
# Copyright (C) 2019 - 2021 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/shadowsocks/go-shadowsocks2
# https://github.com/teddysun/v2ray-plugin
# https://github.com/teddysun/xray-plugin

FROM --platform=${TARGETPLATFORM} alpine:latest
LABEL maintainer="Teddysun <i@teddysun.com>"

ARG TARGETPLATFORM
WORKDIR /root
COPY go-shadowsocks2.sh /root/go-shadowsocks2.sh
COPY v2ray-plugin.sh /root/v2ray-plugin.sh
COPY xray-plugin.sh /root/xray-plugin.sh
RUN set -ex \
	&& apk add --no-cache tzdata \
	&& chmod +x /root/go-shadowsocks2.sh /root/v2ray-plugin.sh /root/xray-plugin.sh \
	&& /root/go-shadowsocks2.sh "${TARGETPLATFORM}" \
	&& /root/v2ray-plugin.sh "${TARGETPLATFORM}" \
	&& /root/xray-plugin.sh "${TARGETPLATFORM}" \
	&& rm -fv /root/go-shadowsocks2.sh /root/v2ray-plugin.sh /root/xray-plugin.sh

ENV TZ=Asia/Shanghai
ENV SERVER_PORT=9000
ENV METHOD=AEAD_CHACHA20_POLY1305
ENV PASSWORD=teddysun.com
ENV ARGS=
CMD exec go-shadowsocks2 \
	-s "ss://${METHOD}:${PASSWORD}@:${SERVER_PORT}" \
	-verbose \
	${ARGS}