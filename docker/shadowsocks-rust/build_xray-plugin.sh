#!/bin/bash
#
# This is a Shell script for build multi-architectures xray-plugin binary file
# 
# Supported architectures: amd64, arm32v6, arm32v7, arm64v8, i386, ppc64le, s390x
# 
# Copyright (C) 2021 Teddysun <i@teddysun.com>
#
# Reference URL:
# https://github.com/teddysun/xray-plugin

cur_dir="$(pwd)"

COMMANDS=( git go )
for CMD in "${COMMANDS[@]}"; do
    if [ ! "$(command -v "${CMD}")" ]; then
        echo "${CMD} is not installed, please install it and try again" && exit 1
    fi
done

cd ${cur_dir}
git clone https://github.com/teddysun/xray-plugin.git
cd xray-plugin || exit 2

VERSION="$(git describe --tags)"
LDFLAGS="-X main.VERSION=$VERSION -s -w"
ARCHS=( 386 amd64 arm arm64 ppc64le s390x )
ARMS=( 6 7 )

for ARCH in ${ARCHS[@]}; do
    if [ "${ARCH}" = "arm" ]; then
        for V in ${ARMS[@]}; do
            echo "Building xray-plugin_linux_${ARCH}${V}"
            env CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} GOARM=${V} go build -v -trimpath -ldflags "${LDFLAGS}" -o ${cur_dir}/xray-plugin_linux_${ARCH}${V}
        done
    else
        echo "Building xray-plugin_linux_${ARCH}"
        env CGO_ENABLED=0 GOOS=linux GOARCH=${ARCH} go build -v -trimpath -ldflags "${LDFLAGS}" -o ${cur_dir}/xray-plugin_linux_${ARCH}
    fi
done

# clean up
cd ${cur_dir} && rm -fr xray-plugin
