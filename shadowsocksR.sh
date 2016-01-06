#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=================================================================#
#   System Required:  CentOS 6,7, Debian, Ubuntu                  #
#   Description: One click Install ShadowsocksR Server            #
#   Author: Teddysun <i@teddysun.com>                             #
#   Thanks: @breakwa11 <https://twitter.com/breakwa11>            #
#   Intro:  https://shadowsocks.be/9.html                         #
#=================================================================#

clear
echo ""
echo "#############################################################"
echo "# One click Install ShadowsocksR Server                     #"
echo "# Intro: https://shadowsocks.be/9.html                      #"
echo "# Author: Teddysun <i@teddysun.com>                         #"
echo "# Thanks: @breakwa11 <https://twitter.com/breakwa11>        #"
echo "#############################################################"
echo ""

#Current folder
cur_dir=`pwd`
# Get public IP address
IP=$(ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\." | head -n 1)
if [[ "$IP" = "" ]]; then
    IP=$(wget -qO- -t1 -T2 ipv4.icanhazip.com)
fi

# Make sure only root can run our script
function rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

# Check OS
function checkos(){
    if [ -f /etc/redhat-release ];then
        OS='CentOS'
    elif [ ! -z "`cat /etc/issue | grep bian`" ];then
        OS='Debian'
    elif [ ! -z "`cat /etc/issue | grep Ubuntu`" ];then
        OS='Ubuntu'
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}

# Get version
function getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else    
        grep -oE  "[0-9.]+" /etc/issue
    fi    
}

# CentOS version
function centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi        
}

# Disable selinux
function disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}

# Pre-installation settings
function pre_install(){
    # Not support CentOS 5
    if centosversion 5; then
        echo "Not support CentOS 5.x, please change OS to CentOS 6,7/Debian/Ubuntu and retry."
        exit 1
    fi
    # Set ShadowsocksR config password
    echo "Please input password for ShadowsocksR:"
    read -p "(Default password: teddysun.com):" shadowsockspwd
    [ -z "$shadowsockspwd" ] && shadowsockspwd="teddysun.com"
    echo ""
    echo "---------------------------"
    echo "password = $shadowsockspwd"
    echo "---------------------------"
    echo ""
    # Set ShadowsocksR config port
    while true
    do
    echo -e "Please input port for ShadowsocksR [1-65535]:"
    read -p "(Default port: 8989):" shadowsocksport
    [ -z "$shadowsocksport" ] && shadowsocksport="8989"
    expr $shadowsocksport + 0 &>/dev/null
    if [ $? -eq 0 ]; then
        if [ $shadowsocksport -ge 1 ] && [ $shadowsocksport -le 65535 ]; then
            echo ""
            echo "---------------------------"
            echo "port = $shadowsocksport"
            echo "---------------------------"
            echo ""
            break
        else
            echo "Input error! Please input correct number."
        fi
    else
        echo "Input error! Please input correct number."
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
    # Install necessary dependencies
    if [ "$OS" == 'CentOS' ]; then
        yum install -y wget unzip openssl-devel gcc swig python python-devel python-setuptools autoconf libtool libevent
        yum install -y m2crypto automake make curl curl-devel zlib-devel perl perl-devel cpio expat-devel gettext-devel
    else
        apt-get -y update
        apt-get -y install python python-dev python-pip python-m2crypto curl wget unzip gcc swig automake make perl cpio build-essential
    fi
    cd $cur_dir
}

# Download files
function download_files(){
    # Download libsodium file
    if ! wget --no-check-certificate -O libsodium-1.0.8.tar.gz https://github.com/jedisct1/libsodium/releases/download/1.0.8/libsodium-1.0.8.tar.gz; then
        echo "Failed to download libsodium file!"
        exit 1
    fi
    # Download ShadowsocksR file
    if ! wget --no-check-certificate -O manyuser.zip https://github.com/breakwa11/shadowsocks/archive/manyuser.zip; then
        echo "Failed to download ShadowsocksR file!"
        exit 1
    fi
    # Download ShadowsocksR chkconfig file
    if [ "$OS" == 'CentOS' ]; then
        if ! wget --no-check-certificate https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocksR -O /etc/init.d/shadowsocks; then
            echo "Failed to download ShadowsocksR chkconfig file!"
            exit 1
        fi
    else
        if ! wget --no-check-certificate https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocksR-debian -O /etc/init.d/shadowsocks; then
            echo "Failed to download ShadowsocksR chkconfig file!"
            exit 1
        fi
    fi
}

# Config ShadowsocksR
function config_shadowsocks(){
    cat > /etc/shadowsocks.json<<-EOF
{
    "server":"0.0.0.0",
    "server_ipv6":"::",
    "server_port":${shadowsocksport},
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"${shadowsockspwd}",
    "timeout":120,
    "method":"aes-256-cfb",
    "protocol":"origin",
    "protocol_param":"",
    "obfs":"plain",
    "obfs_param":"",
    "redirect":"",
    "dns_ipv6":false,
    "fast_open":false,
    "workers":1
}
EOF
}

# Install ShadowsocksR
function install_ss(){
    # Install libsodium
    tar zxf libsodium-1.0.8.tar.gz
    cd $cur_dir/libsodium-1.0.8
    ./configure && make && make install
    ldconfig
    # Install ShadowsocksR
    cd $cur_dir
    unzip -q manyuser.zip
    mv shadowsocks-manyuser/shadowsocks /usr/local/
    if [ -f /usr/local/shadowsocks/server.py ]; then
        chmod +x /etc/init.d/shadowsocks
        # Add run on system start up
        if [ "$OS" == 'CentOS' ]; then
            chkconfig --add shadowsocks
            chkconfig shadowsocks on
        else
            update-rc.d shadowsocks defaults
        fi
        # Run ShadowsocksR in the background
        /etc/init.d/shadowsocks start
        clear
        echo ""
        echo "Congratulations, ShadowsocksR install completed!"
        echo -e "Server IP: \033[41;37m ${IP} \033[0m"
        echo -e "Server Port: \033[41;37m ${shadowsocksport} \033[0m"
        echo -e "Password: \033[41;37m ${shadowsockspwd} \033[0m"
        echo -e "Local IP: \033[41;37m 127.0.0.1 \033[0m"
        echo -e "Local Port: \033[41;37m 1080 \033[0m"
        echo -e "Protocol: \033[41;37m origin \033[0m"
        echo -e "obfs: \033[41;37m plain \033[0m"
        echo -e "Encryption Method: \033[41;37m aes-256-cfb \033[0m"
        echo ""
        echo "Welcome to visit:https://shadowsocks.be/9.html"
        echo "If you want to change protocol & obfs, reference URL:"
        echo "https://github.com/breakwa11/shadowsocks-rss/wiki/Server-Setup"
        echo ""
        echo "Enjoy it!"
        echo ""
    else
        echo "Shadowsocks install failed! Please Email to Teddysun <i@teddysun.com> and contact."
        install_cleanup
        exit 1
    fi
}

# Install cleanup
function install_cleanup(){
    cd $cur_dir
    rm -f manyuser.zip
    rm -rf shadowsocks-manyuser
    rm -f libsodium-1.0.8.tar.gz
    rm -rf libsodium-1.0.8
}


# Uninstall ShadowsocksR
function uninstall_shadowsocks(){
    printf "Are you sure uninstall ShadowsocksR? (y/n) "
    printf "\n"
    read -p "(Default: n):" answer
    if [ -z $answer ]; then
        answer="n"
    fi
    if [ "$answer" = "y" ]; then
        /etc/init.d/shadowsocks status > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/shadowsocks stop
        fi
        checkos
        if [ "$OS" == 'CentOS' ]; then
            chkconfig --del shadowsocks
        else
            update-rc.d -f shadowsocks remove
        fi
        rm -f /etc/shadowsocks.json
        rm -f /etc/init.d/shadowsocks
        rm -rf /usr/local/shadowsocks
        echo "ShadowsocksR uninstall success!"
    else
        echo "uninstall cancelled, Nothing to do"
    fi
}

# Install ShadowsocksR
function install_shadowsocks(){
    checkos
    rootness
    disable_selinux
    pre_install
    download_files
    config_shadowsocks
    install_ss
    install_cleanup
}

# Initialization step
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_shadowsocks
    ;;
uninstall)
    uninstall_shadowsocks
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall}"
    ;;
esac
