#!/bin/sh
#
# This is a Shell script for shadowsocks-rust based alpine with Docker image
# 
# Copyright (C) 2019 - 2021 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/shadowsocks/shadowsocks-rust
# https://github.com/shadowsocks/v2ray-plugin
# https://github.com/teddysun/v2ray-plugin
# https://github.com/teddysun/xray-plugin

PLATFORM=$1
if [ -z "$PLATFORM" ]; then
    ARCH="x86_64-unknown-linux-musl"
else
    case "$PLATFORM" in
        linux/386)
            ARCH=""
            ;;
        linux/amd64)
            ARCH="x86_64-unknown-linux-musl"
            ;;
        linux/arm/v6)
            ARCH="arm-unknown-linux-musleabi"
            ;;
        linux/arm/v7)
            ARCH="arm-unknown-linux-musleabihf"
            ;;
        linux/arm64|linux/arm64/v8)
            ARCH="aarch64-unknown-linux-musl"
            ;;
        linux/ppc64le)
            ARCH=""
            ;;
        linux/s390x)
            ARCH=""
            ;;
        *)
            ARCH=""
            ;;
    esac
fi
[ -z "${ARCH}" ] && echo "Error: Not supported OS Architecture" && exit 1
VERSION=$(wget --no-check-certificate -qO- https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep 'tag_name' | cut -d\" -f4)
[ -z "${VERSION}" ] && echo "Error: Get shadowsocks-rust latest version failed" && exit 1
# Download shadowsocks-rust binary file
SHADOWSOCKS_RUST_FILE="shadowsocks-${VERSION}.${ARCH}.tar.xz"
SHADOWSOCKS_RUST_URL="https://github.com/shadowsocks/shadowsocks-rust/releases/download/${VERSION}/${SHADOWSOCKS_RUST_FILE}"
echo "Downloading shadowsocks-rust binary file: ${SHADOWSOCKS_RUST_FILE}"
wget -O ${SHADOWSOCKS_RUST_FILE} ${SHADOWSOCKS_RUST_URL} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to download shadowsocks-rust binary file: ${SHADOWSOCKS_RUST_FILE}" && exit 1
fi
echo "Download shadowsocks-rust binary file: ${SHADOWSOCKS_RUST_FILE} completed"
echo "Extracting ${SHADOWSOCKS_RUST_FILE}..."
tar Jxf ${SHADOWSOCKS_RUST_FILE} -C /usr/bin
chmod +x /usr/bin/ss*
rm -f ${SHADOWSOCKS_RUST_FILE}
echo "Install shadowsocks-rust binary file: ${SHADOWSOCKS_RUST_FILE} completed"
