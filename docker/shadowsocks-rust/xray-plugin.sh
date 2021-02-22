#!/bin/sh
#
# This is a Shell script for shadowsocks-rust supported SIP003 plugins based alpine with Docker image
# 
# Copyright (C) 2019 - 2021 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/teddysun/xray-plugin

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
# Download xray-plugin binary file
XRAY_PLUGIN_FILE="xray-plugin_linux_${ARCH}"
echo "Downloading xray-plugin binary file: ${XRAY_PLUGIN_FILE}"
wget -O /usr/bin/xray-plugin https://dl.lamp.sh/files/${XRAY_PLUGIN_FILE} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Failed to download xray-plugin binary file: ${XRAY_PLUGIN_FILE}" && exit 1
fi
chmod +x /usr/bin/xray-plugin
echo "Download xray-plugin binary file: ${XRAY_PLUGIN_FILE} completed"
