#!/usr/bin/env bash
#=================================================================#
#   System Required:  CentOS, Debian, Ubuntu                      #
#   Description: Check Shadowsocks Server is running or not       #
#   Author: Teddysun <i@teddysun.com>                             #
#   Visit: https://shadowsocks.be/6.html                          #
#=================================================================#

name=(Shadowsocks Shadowsocks-Python ShadowsocksR Shadowsocks-Go Shadowsocks-libev)
path=/var/log
[[ ! -d ${path} ]] && mkdir -p ${path}
log=${path}/shadowsocks-crond.log

shadowsocks[0]=/usr/bin/ssserver
shadowsocks[1]=/usr/local/bin/ssserver
shadowsocks[2]=/usr/bin/shadowsocks-server
shadowsocks[3]=/usr/local/bin/ss-server
shadowsocks[4]=/usr/local/shadowsocks/server.py

shadowsocks_init[0]=/etc/init.d/shadowsocks
shadowsocks_init[1]=/etc/init.d/shadowsocks-python
shadowsocks_init[2]=/etc/init.d/shadowsocks-r
shadowsocks_init[3]=/etc/init.d/shadowsocks-go
shadowsocks_init[4]=/etc/init.d/shadowsocks-libev

i=0
for init in ${shadowsocks_init[@]}; do
    pid=""
    if [ -f ${init} ]; then
        ${init} status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            for bin in ${shadowsocks[@]}; do
                pid=`ps -ef | grep -v grep | grep -i "${bin}" | awk '{print $2}'` 
                if [ ! -z ${pid} ]; then
                    break
                fi
            done
        fi

        if [ -z ${pid} ]; then
            echo "`date +"%Y-%m-%d %H:%M:%S"` ${name[$i]} is not running" >> ${log}
            echo "`date +"%Y-%m-%d %H:%M:%S"` Starting ${name[$i]}" >> ${log}
            ${init} start &>/dev/null
            if [ $? -eq 0 ]; then
                echo "`date +"%Y-%m-%d %H:%M:%S"` ${name[$i]} start success" >> ${log}
            else
                echo "`date +"%Y-%m-%d %H:%M:%S"` ${name[$i]} start failed" >> ${log}
            fi
        else
            echo "`date +"%Y-%m-%d %H:%M:%S"` ${name[$i]} is running with pid $pid" >> ${log}
        fi
    
    fi
    ((i++))
done
