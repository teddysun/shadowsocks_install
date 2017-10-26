#!/usr/bin/env bash
#
# System Required:  CentOS, Debian, Ubuntu
#
# Description: Install haproxy for Shadowsocks server
#
# Author: Teddysun <i@teddysun.com>
#
# Intro:  https://shadowsocks.be/10.html
#

cur_dir=`pwd`

[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root!" && exit 1

clear
echo
echo "#############################################################"
echo "# Install haproxy for Shadowsocks server                    #"
echo "# Intro: https://shadowsocks.be/10.html                     #"
echo "# Author: Teddysun <i@teddysun.com>                         #"
echo "#############################################################"
echo

check_sys() {
    local checkType=$1
    local value=$2

    local release=''
    local systemPackage=''

    if [ -f /etc/redhat-release ]; then
        release="centos"
        systemPackage="yum"
    elif cat /etc/issue | grep -Eqi "debian"; then
        release="debian"
        systemPackage="apt"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        release="ubuntu"
        systemPackage="apt"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        systemPackage="yum"
    elif cat /proc/version | grep -Eqi "debian"; then
        release="debian"
        systemPackage="apt"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        release="ubuntu"
        systemPackage="apt"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        release="centos"
        systemPackage="yum"
    fi

    if [ ${checkType} == "sysRelease" ]; then
        if [ "$value" == "$release" ]; then
            return 0
        else
            return 1
        fi
    elif [ ${checkType} == "packageManager" ]; then
        if [ "$value" == "$systemPackage" ]; then
            return 0
        else
            return 1
        fi
    fi
}

install_check() {
    if check_sys packageManager yum || check_sys packageManager apt; then
        return 0
    else
        return 1
    fi
}

disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

valid_ip(){
    local ip=$1
    local stat=1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return ${stat}
}

get_ip(){
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ ! -z ${IP} ] && echo ${IP} || echo
}

get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

# Pre-installation settings
pre_install(){
    if ! install_check; then
        echo "Your OS is not supported to run it."
        echo "Please change to CentOS 6+/Debian 7+/Ubuntu 12+ and try again."
        exit 1
    fi

    # Set haproxy config port
    while true
    do
    echo -e "Please enter a port for haproxy and Shadowsocks server [1-65535]"
    read -p "(Default port: 8989):" haproxyport
    [ -z "${haproxyport}" ] && haproxyport="8989"
    expr ${haproxyport} + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${haproxyport} -ge 1 ] && [ ${haproxyport} -le 65535 ]; then
            echo
            echo "---------------------------"
            echo "port = ${haproxyport}"
            echo "---------------------------"
            echo
            break
        else
            echo "Enter error! Please enter a correct number."
        fi
    else
        echo "Enter error! Please enter a correct number."
    fi
    done

    # Set haproxy config IPv4 address
    while :
    do
    echo -e "Please enter your Shadowsocks server's IPv4 address for haproxy"
    read -p "(IPv4 is):" haproxyip
    valid_ip ${haproxyip}
    if [ $? -eq 0 ]; then
        echo
        echo "---------------------------"
        echo "IP = ${haproxyip}"
        echo "---------------------------"
        echo
        break
    else
        echo "Enter error! Please enter correct IPv4 address."
    fi
    done

    echo
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`

}

# Config haproxy
config_haproxy(){
    # Config DNS nameserver
    if ! grep -q "8.8.8.8" /etc/resolv.conf; then
        cp -p /etc/resolv.conf /etc/resolv.conf.bak
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    fi

    if [ -f /etc/haproxy/haproxy.cfg ]; then
        cp -p /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
    fi

    cat > /etc/haproxy/haproxy.cfg<<-EOF
global
    ulimit-n    51200
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user        haproxy
    group       haproxy
    daemon

defaults
    mode                    tcp
    log                     global
    option                  dontlognull
    timeout connect         5s
    timeout client          1m
    timeout server          1m

frontend ss-${haproxyport}
        bind *:${haproxyport}
        default_backend ss-${haproxyport}
backend ss-${haproxyport}
        server server1 ${haproxyip}:${haproxyport} maxconn 20480
EOF
}

install(){
    # Install haproxy
    if check_sys packageManager yum; then
        yum install -y haproxy
    elif check_sys packageManager apt; then
        apt-get -y update
        apt-get install -y haproxy
    fi

    if [ -d /etc/haproxy ]; then
        echo "haproxy install success."

        echo "Config haproxy start..."
        config_haproxy
        echo "Config haproxy completed..."

        if check_sys packageManager yum; then
            chkconfig --add haproxy
            chkconfig haproxy on
        elif check_sys packageManager apt; then
            update-rc.d haproxy defaults
        fi

        # Start haproxy
        service haproxy start
        if [ $? -eq 0 ]; then
            echo "haproxy start success..."
        else
            echo "haproxy start failure..."
        fi
    else
        echo
        echo "haproxy install failed."
        exit 1
    fi

    sleep 3
    # restart haproxy
    service haproxy restart
    # Active Internet connections confirm
    netstat -nxtlp
    echo
    echo "Congratulations, haproxy install completed."
    echo -e "Your haproxy Server IP: \033[41;37m $(get_ip) \033[0m"
    echo -e "Your haproxy Server port: \033[41;37m ${haproxyport} \033[0m"
    echo -e "Your Input Shadowsocks IP: \033[41;37m ${haproxyip} \033[0m"
    echo
    echo "Welcome to visit: https://shadowsocks.be/10.html"
    echo "Enjoy it."
    echo
}


# Install haproxy
install_haproxy(){
    disable_selinux
    pre_install
    install
}

# Initialization step
install_haproxy 2>&1 | tee ${cur_dir}/haproxy_for_shadowsocks.log
