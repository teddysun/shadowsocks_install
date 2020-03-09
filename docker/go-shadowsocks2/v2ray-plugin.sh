#!/bin/sh
#
# This is a Shell script for go-shadowsocks2 supported SIP003 plugins based alpine with Docker image
# 
# Copyright (C) 2019 - 2020 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/shadowsocks/shadowsocks-libev
# https://github.com/shadowsocks/simple-obfs
# https://github.com/shadowsocks/v2ray-plugin

PLATFORM=$1
if [ -z "$PLATFORM" ]; then
    ARCH="amd64"
else
    case "$PLATFORM" in
        linux/386)
            ARCH="386"
            ;;
        linux/amd64)
            ARCH="amd64"
            ;;
        linux/arm/v6)
            ARCH="arm6"
            ;;
        linux/arm/v7)
            ARCH="arm7"
            ;;
        linux/arm64|linux/arm64/v8)
            ARCH="arm64"
            ;;
        linux/ppc64le)
            ARCH="ppc64le"
            ;;
        linux/s390x)
            ARCH="s390x"
            ;;
        *)
            ARCH=""
            ;;
    esac
fi
[ -z "${ARCH}" ] && echo "Error: Not supported OS Architecture" && exit 1
# Download v2ray-plugin binary file
V2RAY_PLUGIN_FILE="v2ray-plugin_linux_${ARCH}"
echo "Downloading v2ray-plugin binary file: ${V2RAY_PLUGIN_FILE}"
wget -O /usr/bin/v2ray-plugin https://dl.lamp.sh/files/${V2RAY_PLUGIN_FILE} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to download v2ray-plugin binary file: ${V2RAY_PLUGIN_FILE}" && exit 1
fi
chmod +x /usr/bin/v2ray-plugin
echo "Download v2ray-plugin binary file: ${V2RAY_PLUGIN_FILE} completed"
