#!/bin/bash
# Check Shadowsocks Server is running or not
# Author: Teddysun <i@teddysun.com>
# Visit: https://shadowsocks.be/6.html

# name
name=Shadowsocks
# log path
path=/var/log
# check log path
[[ ! -d $path ]] && mkdir -p $path
# log file
log=$path/shadowsocks-crond.log
# shadowsocks-python path(centos)
bin1=/usr/bin/ssserver
# shadowsocks-python path(debian)
bin2=/usr/local/bin/ssserver
# shadowsocks-go path
bin3=/usr/bin/shadowsocks-server
# shadowsocks-libev path
bin4=/usr/local/bin/ss-server
# shadowsocksR path
bin5=/usr/local/shadowsocks/server.py
# default pid value
pid=""

# check Shadowsocks status
/etc/init.d/shadowsocks status &>/dev/null
if [ $? -eq 0 ]; then
    pid=`ps -ef | grep -v grep | grep -v ps | grep -i "${bin1}" | awk '{print $2}'` 
    if [ -z $pid ]; then
        pid=`ps -ef | grep -v grep | grep -v ps | grep -i "${bin2}" | awk '{print $2}'` 
        if [ -z $pid ]; then
            pid=`ps -ef | grep -v grep | grep -v ps | grep -i "${bin3}" | awk '{print $2}'` 
            if [ -z $pid ]; then
                pid=`ps -ef | grep -v grep | grep -v ps | grep -i "${bin4}" | awk '{print $2}'` 
                if [ -z $pid ]; then
                    pid=`ps -ef | grep -v grep | grep -v ps | grep -i "${bin5}" | awk '{print $2}'` 
                fi
            fi
        fi
    fi
fi

# check status & auto start
if [[ -z $pid ]]; then
    echo "`date +"%Y-%m-%d %H:%M:%S"` $name is not running" >> $log
    echo "`date +"%Y-%m-%d %H:%M:%S"` Starting $name" >> $log
    /etc/init.d/shadowsocks start &>/dev/null
    if [ $? -eq 0 ]; then
        echo "`date +"%Y-%m-%d %H:%M:%S"` $name start success" >> $log
    else
        echo "`date +"%Y-%m-%d %H:%M:%S"` $name start failed" >> $log
    fi
else
    echo "`date +"%Y-%m-%d %H:%M:%S"` $name is running with pid $pid" >> $log
fi
