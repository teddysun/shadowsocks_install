#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  CentOS, Debian, Ubuntu                      #
#   Description: Install haproxy for Shadowsocks server           #
#   Author: Teddysun <i@teddysun.com>                             #
#   Intro:  https://shadowsocks.be/10.html                        #
#=================================================================#

clear
echo ""
echo "#############################################################"
echo "# Install haproxy for Shadowsocks server                    #"
echo "# Intro: https://shadowsocks.be/10.html                     #"
echo "# Author: Teddysun <i@teddysun.com>                         #"
echo "#############################################################"
echo ""

rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

checkos(){
    if [[ -f /etc/redhat-release ]];then
        OS=CentOS
    elif cat /etc/issue | grep -q -E -i "debian";then
        OS=Debian
    elif cat /etc/issue | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    elif cat /proc/version | grep -q -E -i "debian";then
        OS=Debian
    elif cat /proc/version | grep -q -E -i "ubuntu";then
        OS=Ubuntu
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat";then
        OS=CentOS
    else
        echo "Not supported OS, Please reinstall OS and try again."
        exit 1
    fi
}

disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

valid_ip(){
    local  ip=$1
    local  stat=1
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
    local IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\." | head -n 1 )
    if [ -z ${IP} ]; then
        IP=$( wget -qO- -t1 -T2 ipv4.icanhazip.com )
    fi
    echo ${IP}
}

# Pre-installation settings
function pre_install(){
    # Set haproxy config port
    while :
    do
    echo -e "Please input port for haproxy & shadowsocks [1-65535]"
    read -p "(Default port: 8989):" haproxyport
    [ -z "${haproxyport}" ] && haproxyport="8989"
    expr ${haproxyport} + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ ${haproxyport} -ge 1 ] && [ ${haproxyport} -le 65535 ]; then
            echo ""
            echo "---------------------------"
            echo "port = ${haproxyport}"
            echo "---------------------------"
            echo ""
            break
        else
            echo "Input error! Please input correct numbers."
        fi
    else
        echo "Input error! Please input correct numbers."
    fi
    done

    # Set haproxy config IPv4 address
    while :
    do
    echo -e "Please input your shadowsocks IPv4 address for haproxy"
    read -p "(IPv4 is):" haproxyip
    valid_ip ${haproxyip}
    if [ $? -eq 0 ]; then
        echo ""
        echo "---------------------------"
        echo "IP = ${haproxyip}"
        echo "---------------------------"
        echo ""
        break
    else
        echo "Input error! Please input correct IPv4 address."
    fi
    done

    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo ""
    echo "Press any key to start...or Press Ctrl+C to cancel"
    char=`get_char`

}

# Config haproxy
config_haproxy(){
    # Config DNS nameserver
    if ! grep -q "8.8.8.8" /etc/resolv.conf;then
        cp -p /etc/resolv.conf /etc/resolv.conf.bak
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    fi

    if [ -f /etc/haproxy/haproxy.cfg ];then
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
    if [ "${OS}" == 'CentOS' ];then
        yum install -y haproxy
    else
        apt-get -y update
        apt-get install -y haproxy
    fi

    if [ -d /etc/haproxy ]; then
        echo "haproxy install successed."

        echo "Config haproxy start..."
        config_haproxy
        echo "Config haproxy completed..."

        if [ "${OS}" == 'CentOS' ]; then
            chkconfig --add haproxy
            chkconfig haproxy on
        else
            update-rc.d haproxy defaults
        fi

        # Start haproxy
        /etc/init.d/haproxy start
        if [ $? -eq 0 ]; then
            echo "haproxy start success..."
        else
            echo "haproxy start failure..."
        fi
    else
        echo ""
        echo "haproxy install failed."
        exit 1
    fi

    sleep 3
    # restart haproxy
    /etc/init.d/haproxy restart
    # Active Internet connections confirm
    netstat -nxtlp
    echo
    echo "Congratulations, haproxy install completed."
    echo -e "Your haproxy Server IP: \033[41;37m `get_ip` \033[0m"
    echo -e "Your haproxy Server port: \033[41;37m ${haproxyport} \033[0m"
    echo -e "Your Input Shadowsocks IP: \033[41;37m ${haproxyip} \033[0m"
    echo
    echo "Welcome to visit:https://shadowsocks.be/10.html"
    echo "Enjoy it."
    echo
    exit 0
}


# Install haproxy
install_haproxy(){
    checkos
    rootness
    disable_selinux
    pre_install
    install
}

# Initialization step
install_haproxy 2>&1 | tee -a /root/haproxy_for_shadowsocks.log
