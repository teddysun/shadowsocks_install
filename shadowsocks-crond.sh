#!/usr/bin/env bash
#=================================================================#
#   System Required:  CentOS, Debian, Ubuntu                      #
#   Description: Check Shadowsocks Server is running or not       #
#   Author: Teddysun <i@teddysun.com>                             #
#   Visit: https://shadowsocks.be/6.html                          #
#=================================================================#

# name
name=Shadowsocks
# log path
path=/var/log
# check log path
[[ ! -d ${path} ]] && mkdir -p ${path}
# log file
log=${path}/shadowsocks-crond.log
# shadowsocks-python path(centos)
shadowsocks[0]=/usr/bin/ssserver
# shadowsocks-python path(debian)
shadowsocks[1]=/usr/local/bin/ssserver
# shadowsocks-go path
shadowsocks[2]=/usr/bin/shadowsocks-server
# shadowsocks-libev path
shadowsocks[3]=/usr/local/bin/ss-server
# shadowsocksR path
shadowsocks[4]=/usr/local/shadowsocks/server.py
# default pid value
pid=""

[ ! -f /etc/init.d/shadowsocks ] && echo "`date +"%Y-%m-%d %H:%M:%S"` /etc/init.d/shadowsocks is not existed" >> ${log} && exit

# check Shadowsocks status
/etc/init.d/shadowsocks status &>/dev/null
if [ $? -eq 0 ]; then
    for bin in ${shadowsocks[*]}
    do
        pid=`ps -ef | grep -v grep | grep -i "${bin}" | awk '{print $2}'` 
        if [ ! -z ${pid} ]; then
            break
        fi
    done
fi

# check status & auto start
if [ -z ${pid} ]; then
    echo "`date +"%Y-%m-%d %H:%M:%S"` $name is not running" >> ${log}
    echo "`date +"%Y-%m-%d %H:%M:%S"` Starting $name" >> ${log}
    /etc/init.d/shadowsocks start &>/dev/null
    if [ $? -eq 0 ]; then
        echo "`date +"%Y-%m-%d %H:%M:%S"` $name start success" >> ${log}
    else
        echo "`date +"%Y-%m-%d %H:%M:%S"` $name start failed" >> ${log}
    fi
else
    echo "`date +"%Y-%m-%d %H:%M:%S"` $name is running with pid $pid" >> ${log}
fi
