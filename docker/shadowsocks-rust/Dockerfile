# Dockerfile for shadowsocks-rust based alpine
# Copyright (C) 2020 - 2021 Teddysun <i@teddysun.com>
# Reference URL:
# https://github.com/shadowsocks/shadowsocks-rust
# https://github.com/shadowsocks/v2ray-plugin
# https://github.com/teddysun/v2ray-plugin
# https://github.com/teddysun/xray-plugin

FROM alpine:edge

WORKDIR /root
COPY v2ray-plugin.sh /root/v2ray-plugin.sh
COPY xray-plugin.sh /root/xray-plugin.sh
COPY config_sample.json /etc/shadowsocks-rust/config.json
RUN set -ex \
	&& runDeps="git build-base c-ares-dev autoconf automake libev-dev libtool libsodium-dev linux-headers mbedtls-dev pcre-dev openssl-dev cargo" \
	&& apk add --no-cache --virtual .build-deps ${runDeps} \
	&& mkdir -p /root/rust \
	&& cd /root/rust \
	&& VERSION=$(wget --no-check-certificate -qO- https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep 'tag_name' | cut -d\" -f4) \
	&& git clone -b ${VERSION} --depth=1 https://github.com/shadowsocks/shadowsocks-rust.git . \
	&& cargo build --release --features "aes-pmac-siv local-redir" --verbose \
	&& cp -pv target/release/sslocal /usr/bin \
	&& cp -pv target/release/ssmanager /usr/bin \
	&& cp -pv target/release/ssserver /usr/bin \
	&& cp -pv target/release/ssurl /usr/bin \
	&& apk add --no-cache \
		tzdata \
		rng-tools \
		ca-certificates \
		libgcc \
		$(scanelf --needed --nobanner /usr/bin/ss* \
		| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
		| xargs -r apk info --installed \
		| sort -u) \
	&& apk del .build-deps \
	&& cd /root \
	&& rm -rf /root/rust \
	&& chmod +x /root/v2ray-plugin.sh /root/xray-plugin.sh \
	&& /root/v2ray-plugin.sh \
	&& /root/xray-plugin.sh \
	&& rm -f /root/v2ray-plugin.sh /root/xray-plugin.sh

VOLUME /etc/shadowsocks-rust
ENV TZ=Asia/Shanghai
CMD [ "/usr/bin/ssserver", "-c", "/etc/shadowsocks-rust/config.json" ]
