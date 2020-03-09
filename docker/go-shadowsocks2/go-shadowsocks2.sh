#!/bin/sh
#
# This is a Shell script for go-shadowsocks2 based alpine with Docker image
# 
# Copyright (C) 2019 - 2020 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/shadowsocks/go-shadowsocks2

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
# Download binary file
GO_SHADOWSOCKS2_FILE="go-shadowsocks2_linux_${ARCH}"
echo "Downloading go-shadowsocks2 binary file: ${GO_SHADOWSOCKS2_FILE}"
wget -O /usr/bin/go-shadowsocks2 https://dl.lamp.sh/files/${GO_SHADOWSOCKS2_FILE} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to download go-shadowsocks2 binary file: ${GO_SHADOWSOCKS2_FILE}" && exit 1
fi
chmod +x /usr/bin/go-shadowsocks2
echo "Download go-shadowsocks2 binary file: ${GO_SHADOWSOCKS2_FILE} completed"
