#!/bin/bash
# Check Shadowsocks running or not
# Author: Teddysun <i@teddysun.com>
# Visit: https://shadowsocks.be

# name
name=Shadowsocks
# log path
path=/var/log
# log file
log=$path/shadowsocks-crond.log
# shadowsocks-python bin path(centos)
bin1=/usr/bin/ssserver
# shadowsocks-python bin path(debian)
bin2=/usr/local/bin/ssserver
# shadowsocks-go bin path
bin3=/usr/bin/shadowsocks-server
# shadowsocks-libev bin path
bin4=/usr/local/bin/ss-server
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
            fi
        fi
    fi
fi

# check log path
if [ ! -d $path ]; then
    mkdir -p $path
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
